//
//  System.swift
//  PromisedArchitectureKit
//
//  Created by Pallas, Ricardo on 7/3/18.
//

import Foundation
import PromiseKit

public final class System<State, Event> {

    internal var eventQueue = [Event]()
    internal var callback: ((State, [State]) -> ())? = nil

    internal var initialState: State
    internal var reducer: (State, Event) -> Promise<State>
    internal var uiBindings: [((State) -> ())?]
    internal var currentState: State
    internal var historyOfStates: [State] = []

    private init(
        initialState: State,
        reducer: @escaping (State, Event) -> Promise<State>,
        uiBindings: [((State) -> ())?]
        ) {
        self.initialState = initialState
        self.reducer = reducer
        self.uiBindings = uiBindings
        self.currentState = initialState
    }

    public static func pure(
        initialState: State,
        reducer: @escaping (State, Event) -> Promise<State>,
        uiBindings: [((State) -> ())?]
        ) -> System {
        
        let system = System<State,Event>(initialState: initialState, reducer: reducer, uiBindings: uiBindings)
        system.historyOfStates.append(initialState)
        system.bindUI(initialState)
        return system
    }

    public func addLoopCallback(callback: @escaping (State, [State])->()){
        self.callback = callback
    }

    var actionExecuting = false

    public func sendEvent(_ action: Event) {
        assert(Thread.isMainThread)
        if actionExecuting {
            self.eventQueue.append(action)
        } else {
            actionExecuting = true
            let _ = doLoop(action).done { state in
                self.actionExecuting = false
                if let nextEvent = self.eventQueue.first {
                    self.eventQueue.removeFirst()
                    self.sendEvent(nextEvent)
                }
            }
        }
    }

    private func doLoop(_ event: Event) -> Promise<State> {
        return Promise.value(event)
            .then { event -> Promise<State> in
                
                let statePromise = self.reducer(self.currentState, event)

                if let stateWhenLoading = statePromise.loadingState {
                    self.historyOfStates.append(stateWhenLoading)
                    self.bindUI(stateWhenLoading)
                }

                return statePromise
            }
            .map { state in
                self.currentState = state
                self.historyOfStates.append(state)
                self.bindUI(state)
                return state
            }
    }

    private func bindUI(_ state: State) {
        self.uiBindings.forEach { uiBinding in
            uiBinding?(state)
        }
        self.callback?(state, self.historyOfStates)
    }
}
