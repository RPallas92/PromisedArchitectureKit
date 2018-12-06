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
    internal var callback: ((State) -> ())? = nil

    internal var initialState: State
    internal var reducer: (State, Event) -> AsyncResult<State>
    internal var uiBindings: [((State) -> ())?]
    internal var currentState: State

    private init(
        initialState: State,
        reducer: @escaping (State, Event) -> AsyncResult<State>,
        uiBindings: [((State) -> ())?]
        ) {
        self.initialState = initialState
        self.reducer = reducer
        self.uiBindings = uiBindings
        self.currentState = initialState
    }

    public static func pure(
        initialState: State,
        reducer: @escaping (State, Event) -> AsyncResult<State>,
        uiBindings: [((State) -> ())?]
        ) -> System {
        
        let system = System<State,Event>(initialState: initialState, reducer: reducer, uiBindings: uiBindings)
        system.bindUI(initialState)
        return system
    }

    public func addLoopCallback(callback: @escaping (State)->()){
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
                assert(Thread.isMainThread, "PromisedArchitectureKit: Final callback must be run on main thread")
                if let callback = self.callback {
                    callback(state)
                }
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

                let asyncResultState = self.reducer(self.currentState, event)

                if let stateWhenLoading = asyncResultState.loadingResult {
                    self.bindUI(stateWhenLoading)
                }

                return asyncResultState.promise
            }
            .map { state in
                self.currentState = state
                self.bindUI(state)
                return state
            }
    }

    private func bindUI(_ state: State) {
        self.uiBindings.forEach { uiBinding in
            uiBinding?(state)
        }
    }
}
