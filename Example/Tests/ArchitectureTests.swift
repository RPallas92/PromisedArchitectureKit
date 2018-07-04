//
//  ArchitectureTests.swift
//  PromisedArchitectureKit_Tests
//
//  Created by Pallas, Ricardo on 7/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import PromisedArchitectureKit
import PromiseKit
import UIKit

fileprivate typealias Function = () -> ()
fileprivate typealias Completable = (@escaping Function) -> ()

fileprivate func runInBackground(_ asyncCode: @escaping(@escaping Completable)->()) {
    DispatchQueue.global(qos: .background).async {
        asyncCode { inMainThread in
            DispatchQueue.main.async {
                inMainThread()
            }
        }
    }
}

enum Event {
    case loadCategories
    case categoriesLoaded([String])
}

struct State {
    var categories: [String]
    var shouldLoadData = false
    
    static var empty = State(categories: [], shouldLoadData: false)
    
    static func reduce(state: State, event: Event) -> State {
        switch event {
        case .loadCategories:
            var newState = state
            newState.shouldLoadData = true
            newState.categories = []
            return newState
        case .categoriesLoaded(let categories):
            var newState = state
            newState.shouldLoadData = false
            newState.categories = categories
            return newState
        }
    }
}

class ArchitectureKitTests: XCTestCase {
    
    func testArchitecture(){
        
        let expect = expectation(description: "testArchitecture")
        
        typealias TestSystem = System<State,Event>
        
        func categoriesBinding(state: State) {
            print(state.categories)
        }
        
        func dummyBinding(state: State) {
            print("Dummy binding")
        }
        
        func loadCategories() -> Promise<Event> {
            let categories = ["dev"]
            return Promise { seal in
                runInBackground { runInUI in
                    let event = Event.categoriesLoaded(categories)
                    runInUI {
                        seal.fulfill(event)
                    }
                }
            }
        }
        
        let initialState = State.empty
        let uiBindings = [categoriesBinding, dummyBinding]
        let reactions = [
            Reaction<State, Event>.react({_ in loadCategories()}, when: { $0.shouldLoadData})
        ]
        
        let button = UIButton()
        
        // let action = CustomAction<State, Event>(trigger: Event.loadCategories)
        let action2 = UIButtonAction<State,Event>.onTap(in: button, trigger: Event.loadCategories)
        
        let system = TestSystem.pure(
            initialState: initialState,
            reducer: State.reduce,
            uiBindings: uiBindings,
            actions: [action2],
            reactions: reactions
        )
        
        system.addLoopCallback {
            expect.fulfill()
        }
        
        //Simulate user interaction - Tap button
        //action.execute()
        
        button.sendActions(for: .touchUpInside)
        wait(for: [expect], timeout: 10.0)
    }
    
}
