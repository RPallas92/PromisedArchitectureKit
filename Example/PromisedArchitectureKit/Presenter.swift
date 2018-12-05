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

protocol View: class {
    func updateUI(state: State)
}

// MARK: - Events
enum Event {
    case loadProduct
}

// MARK: - State
enum State {
    case loading
    case showingProduct(Product)
    case showingError(Error)
    
    static func reduce(state: State, event: Event) -> AsyncResult<State> {
        switch event {
        case .loadProduct:
            let productResult = getProduct()
            
            return productResult
                .map { State.showingProduct($0) }
                .mapErrorRecover { State.showingError($0) }
        }
    }
}

fileprivate func getProduct() -> AsyncResult<Product> {
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
    weak var view: View?
    
    init(view: View) {
        self.view = view
    }
    
    func sendEvent(_ event: Event) {
        system?.sendEvent(event)
    }
    
    func controllerLoaded() {
        system = System.pure(
            initialState: State.loading,
            reducer: State.reduce,
            uiBindings: [view?.updateUI]
        )
    }
    
}
