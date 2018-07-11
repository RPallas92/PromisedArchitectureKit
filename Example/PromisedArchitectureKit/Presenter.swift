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
    case showProductDidAddToCart(Product)
    
    static func reduce(state: State, event: Event) -> State {
        switch event {
            
        case .willLoadProduct:
            return .loading
            
        case .didLoadProduct(let product):
            return .showProduct(product)
            
        case .didThrowError(let errorDescription):
            return .showError(errorDescription)
            
        case .willAddToCart:
            var product: Product? {
                switch state {
                case let .showProduct(product): return product
                case let .showProductDidAddToCart(product): return product
                default: return nil
                }
            }
            
            if let product = product {
                return .addingToCart(product)
            } else {
                return .showError("No product")
            }
            
        case .didAddToCart(let product):
            return .showProductDidAddToCart(product)
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

        self.system = System.pure(
            initialState: State.start,
            reducer: State.reduce,
            uiBindings: [view.updateUI],
            actions: actions,
            reactions: reactions()
        )
    }
    
    func reactions() -> [Reaction<State,Event>]{
        let loadingReaction = Reaction<State,Event>.react({ _ in
            self.getProduct().map { Event.didLoadProduct($0) }
        }, when: {
            $0 == State.loading
        })
        
        let addingToCartReaction = Reaction<State,Event>.react({ state in
            guard case let .addingToCart(product) = state else { preconditionFailure() }
            return self.addToCart(product: product)
                .map { Event.didAddToCart($0)}
                .recover({ error -> Promise<Event> in
                    return Promise.value(Event.didThrowError("Error adding to cart"))
                })
            
            
        }, when: { state in
            guard case let .addingToCart(product) = state else { return false }
            return state == State.addingToCart(product)
        })
        return [loadingReaction, addingToCartReaction]
    }
    
    func getProduct() -> Promise<Product> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                seal.fulfill("Yeezy 500")
            }
        }
    }
    
    // It returns error randomly
    func addToCart(product: Product) -> Promise<Product> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let number = Int(arc4random_uniform(10))
                
                if number < 5 {
                    seal.fulfill("\(product) added to cart")
                    
                } else {
                    let error = NSError(domain: "Error", code: 2333, userInfo: nil)
                    seal.reject(error)
                }
            }
        }
    }
}
