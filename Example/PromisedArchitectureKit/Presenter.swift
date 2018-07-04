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
    case loadProduct
    case addToCart
    case addedToCart(String?)
    case productLoaded(String?)
}

enum DataState {
    case error
    case loading
    case loaded
}

// MARK: - State
struct State {
    var product: Product?
    var dataState: DataState
    var shouldLoadProduct = false
    var shouldAddToCart = false
    var error: String?
    var basket = [String]()
    
    static var empty = State(product: nil, dataState: .loading, shouldLoadProduct: false, shouldAddToCart: false, error: nil, basket: [])
    
    static func reduce(state: State, event: Event) -> State {
        switch event {
            
        case .loadProduct:
            var newState = state
            newState.shouldLoadProduct = true
            newState.shouldAddToCart = false
            newState.error = nil
            newState.product = nil
            newState.dataState = .loading
            return newState
            
        case .productLoaded(let product):
            var newState = state
            newState.shouldLoadProduct = false
            newState.shouldAddToCart = false
            newState.error = product != nil ? "Error getting product" : nil
            newState.product = product
            newState.dataState = product != nil ? .error : .loaded
            return newState
            
        case .addToCart:
            var newState = state
            newState.shouldLoadProduct = false
            newState.shouldAddToCart = true
            newState.error = nil
            newState.dataState = .loading
            return newState
            
        case .addedToCart(let product):
            var newState = state
            newState.shouldLoadProduct = false
            newState.shouldAddToCart = false
            if let product = product {
                newState.basket = [product]
            }
            newState.error = newState.isAddedToCart(product) ? nil : "Error while adding to cart"
            newState.dataState = newState.isAddedToCart(product) ? .loaded : .error
            
            return newState
        }
    }
    
    func isAddedToCart(_ product: String?) -> Bool {
        guard let product = product else { return false }
        return self.basket.contains(product)
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
        
        let loadProductReaction = Reaction<State,Event>.react({ _ in self.getProduct().map { Event.productLoaded($0)} }, when: { $0.shouldLoadProduct })

        self.system = System.pure(
            initialState: State.empty,
            reducer: State.reduce,
            uiBindings: [view.updateUI],
            actions: actions,
            reactions: [loadProductReaction]
        )
    }
    
    func getProduct() -> Promise<Product> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                seal.fulfill("Yeezy 500")
            }
        }
    }
}
