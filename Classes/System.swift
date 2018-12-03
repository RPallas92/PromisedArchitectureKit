//
//  System.swift
//  PromisedArchitectureKit
//
//  Created by Pallas, Ricardo on 7/3/18.
//

import Foundation
import PromiseKit

public struct Reaction<State, Event> {
    
    internal var condition: (State) -> (Bool)
    internal var action: (State) -> Promise<Event>
    
    public static func react(_ action: @escaping (State) -> Promise<Event>, when condition: @escaping (State) -> (Bool)) -> Reaction {
        return Reaction(condition: condition, action: action)
    }
    
    func getStateAfterReaction(from state:State, with reducer:@escaping ((State, Event) -> State)) -> Promise<State> {
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
    
    internal var eventQueue = [Event]()
    internal var callback: (() -> ())? = nil
    
    internal var initialState: State
    internal var reducer: (State, Event) -> State
    internal var uiBindings: [(State) -> ()]
    internal var actions: [SystemAction]
    internal var currentState: State
    
    private init(
        initialState: State,
        reducer: @escaping (State, Event) -> State,
        uiBindings: [(State) -> ()],
        actions: [SystemAction]
        ) {
        
        self.initialState = initialState
        self.reducer = reducer
        self.uiBindings = uiBindings
        self.actions = actions
        self.currentState = initialState
        
        self.actions.forEach { action in
            action.addListener(listener: self)
        }
    }
    
    public static func pure(
        initialState: State,
        reducer: @escaping (State, Event) -> State,
        uiBindings: [(State) -> ()],
        actions: [Action<State, Event>]
        ) -> System {
        
        let system = System<State,Event>(initialState: initialState, reducer: reducer, uiBindings: uiBindings, actions: actions)
        
        let _ = system.bindUI(initialState).done { _ in }
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
            let _ = doLoop(action).done { _ in
                assert(Thread.isMainThread, "PromisedArchitectureKit: Final callback must be run on main thread")
                if let callback = self.callback {
                    callback()
                }
                self.actionExecuting = false
                if let nextEvent = self.eventQueue.first {
                    self.eventQueue.removeFirst()
                    self.onAction(nextEvent)
                }
                
            }
        }
    }
    
    private func doLoop(_ event: Event) -> Promise<State> {
        return Promise.value(event)
            .map { event in
                self.reducer(self.currentState, event)
            }
            .map { state in
                self.currentState = state
                return state
            }
            .then { state -> Promise<State> in
                self.bindUI(state)
        }
    }
    
    private func bindUI(_ state: State) -> Promise<State> {
        return Promise<State> { seal in
            self.uiBindings.forEach { uiBinding in
                uiBinding(state)
            }
            seal.fulfill(state)
        }
    }
}
