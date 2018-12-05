//
//  Presenter.swift
//  PromisedArchitectureKit_Example
//
//  Created by Pallas, Ricardo on 7/4/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import PromisedArchitectureKit
import PromiseKit

typealias Product = String
typealias AddToCartResult = String

protocol View {
    func updateUI(state: State)
}

// MARK: - Events
enum Event {
    case loadProduct
}

// MARK: - State
enum State: Equatable {
    case loading
    case showingProduct(AsyncResult<Product>)
    
    static func reduce(state: State, event: Event) -> State { // TODO AsyncResultState
        switch event {
        case .loadProduct:
            let productResult = getProduct()
            
            return .showingProduct(productResult)
        }
            
    }
    
}

private func getProduct() -> AsyncResult<Product> {
    let promise = Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            seal.fulfill("Yeezy 500")
        }
    }

    return AsyncResult<Product>(promise)
}



// MARK: - Presenter
class Presenter {
    
    var system: System<State, Event>?
    let view: View
    let actions: [Action<State, Event>]
    
    init(view: View, actions: [Action<State, Event>]) {
        self.view = view
        self.actions = actions
    }
    
    func controllerLoaded() {

        self.system = System.pure(
            initialState: State.loading,
            reducer: State.reduce,
            uiBindings: [view.updateUI],
            actions: actions
        )
    }
    
}
