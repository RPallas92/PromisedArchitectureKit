//
//  System.swift
//  PromisedArchitectureKit
//
//  Created by Pallas, Ricardo on 7/3/18.
//

import Foundation
import PromiseKit

public struct Feedback<State, Event> {
    
    internal var condition: (State) -> (Bool)
    internal var action: (State) -> Promise<Event>
    
    public static func react(_ action: @escaping (State) -> Promise<Event>, when condition: @escaping (State) -> (Bool)) -> Feedback {
        return Feedback(condition: condition, action: action)
    }
    
    func getStateAfterFeedback(from state:State, with reducer:@escaping ((State, Event) -> State)) -> Promise<State> {
        if self.condition(state) {
            return self.action(state).map { newEvent in
                reducer(state,newEvent)
            }
        } else {
            return Promise.value(state)
        }
    }
}

public final class System<State, Event> {
    
    typealias SystemAction = Action<State, Event>
    typealias SystemFeedback = Feedback<State, Event>
    
    internal var eventQueue = [Event]()
    internal var callback: (() -> ())? = nil
    
    internal var initialState: State
    internal var reducer: (State, Event) -> State
    internal var uiBindings: [(State) -> ()]
    internal var actions: [SystemAction]
    internal var feedback: [SystemFeedback]
    internal var currentState: State
    
    private init(
        initialState: State,
        reducer: @escaping (State, Event) -> State,
        uiBindings: [(State) -> ()],
        actions: [SystemAction],
        feedback: [SystemFeedback]
        ) {
        
        self.initialState = initialState
        self.reducer = reducer
        self.uiBindings = uiBindings
        self.actions = actions
        self.feedback = feedback
        self.currentState = initialState
        
        self.actions.forEach { action in
            action.addListener(listener: self)
        }
    }
    
    public static func pure(
        initialState: State,
        reducer: @escaping (State, Event) -> State,
        uiBindings: [(State) -> ()],
        actions: [Action<State, Event>],
        feedback: [Feedback<State, Event>]
        ) -> System {
        
        let system = System<State,Event>(initialState: initialState, reducer: reducer, uiBindings: uiBindings, actions: actions, feedback: feedback)
        
        let _ = system.bindUI(initialState).done { }
        return system
    }
    
    public func addLoopCallback(callback: @escaping ()->()){
        self.callback = callback
    }
    
    var actionExecuting = false
    
    func onAction(_ action: Event) {
        assert(Thread.isMainThread)
        if actionExecuting {
            self.eventQueue.append(action)
        } else {
            actionExecuting = true
            let _ = doLoop(action).done {
                assert(Thread.isMainThread, "PromisedArchitectureKit: Final callback must be run on main thread")
                if let callback = self.callback {
                    callback()
                    self.actionExecuting = false
                    if let nextEvent = self.eventQueue.first {
                        self.eventQueue.removeFirst()
                        self.onAction(nextEvent)
                    }
                }
            }
        }
    }
    
    private func doLoop(_ event: Event) -> Promise<Void> {
        let maxFeedbackLoops = 5
        
        return Promise.value(event)
            .map { event in
                self.reducer(self.currentState, event)
            }
            .then { state -> Promise<State> in
                self.getStateAfterAllFeedback(from: state, maxFeedbackLoops: maxFeedbackLoops)
            }
            .map { state in
                self.currentState = state
                return state
            }
            .then { state -> Promise<Void> in
                self.bindUI(state)
        }
        
    }
    
    private func getStateAfterAllFeedback(from state: State, maxFeedbackLoops: Int) -> Promise<State> {
        if self.feedback.count > 0 && maxFeedbackLoops > 0 {
            
            let computedStateFeedback = runFeedback(from: state)
        
            return computedStateFeedback.then { arg -> Promise<State> in
                let (_ ,newState) = arg
                
                let anyFeedbackElse = self.feedback.reduce(false, { (otherLoopRequired, feedback) -> Bool in
                    otherLoopRequired || feedback.condition(newState)
                })
                
                if anyFeedbackElse {
                    return self.getStateAfterAllFeedback(from: newState, maxFeedbackLoops: maxFeedbackLoops - 1)
                } else {
                    return Promise.value(newState)
                }
            }
        } else {
            return Promise.value(state)
        }
    }
    
    private func runFeedback(from state:State) -> Promise<(SystemFeedback,State)> {
        
        let firstFeedback = self.feedback.first!
        let initialValue = Promise.value((firstFeedback, state))
        
        return self.feedback.reduce(
            initialValue,
            { (previousFeedbackAndState, feedback) -> Promise<(SystemFeedback,State)> in
                previousFeedbackAndState.then({ (_, state) -> Promise<(SystemFeedback,State)> in
                    feedback.getStateAfterFeedback(from: state, with: self.reducer)
                        .map { newState in
                            (feedback, newState)
                    }
                })
        })
    }
    
    private func bindUI(_ state: State) -> Promise<Void> {
        return Promise<Void> { seal in
            self.uiBindings.forEach { uiBinding in
                uiBinding(state)
            }
            seal.fulfill(())
        }
    }
}
