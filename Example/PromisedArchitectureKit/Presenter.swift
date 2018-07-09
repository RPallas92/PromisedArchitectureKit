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

protocol View {
    func updateUI(state: State)
}

// MARK: - Events
enum Event {
    case willLoadProduct
    case didLoadProduct(Product)
    case didThrowError(String)
    case willAddToCart
    case didAddToCart(Product)
}

// MARK: - State
enum State: Equatable {
    case start
    case loading
    case showProduct(Product)
    case showError(String)
    case addingToCart(Product)
    case showDidAddToCart(Product)
    
    static func reduce(state: State, event: Event) -> State {
        switch event {
            
        case .willLoadProduct:
            return .loading
            
        case .didLoadProduct(let product):
            return .showProduct(product)
            
        case .didThrowError(let errorDescription):
            return .showError(errorDescription)
            
        case .willAddToCart:
            guard case let .showProduct(product) = state else { preconditionFailure() }
            return .addingToCart(product)
            
        case .didAddToCart(let product):
            return .showDidAddToCart(product)
        }
    }
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
        
        let loadProductReaction = Reaction<State,Event>.react({ _ in
            self.getProduct().map {
                Event.didLoadProduct($0)}
            
        }, when: {
            $0 == State.loading }
        )
        
        let addToCartReaction = Reaction<State,Event>.react({ state in
            guard case let .addingToCart(product) = state else { preconditionFailure() }
            return self.addToCart(product: product).map { Event.didAddToCart($0)}
        }, when: { state in
            guard case let .addingToCart(product) = state else { return false }
            return state == State.addingToCart(product)
        })
        
        self.system = System.pure(
            initialState: State.start,
            reducer: State.reduce,
            uiBindings: [view.updateUI],
            actions: actions,
            reactions: [loadProductReaction, addToCartReaction]
        )
    }
    
    func getProduct() -> Promise<Product> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                seal.fulfill("Yeezy 500")
            }
        }
    }
    
    func addToCart(product: Product) -> Promise<Product> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                seal.fulfill("\(product) added to cart")
            }
        }
    }
}
