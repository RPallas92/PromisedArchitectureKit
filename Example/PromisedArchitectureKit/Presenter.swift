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
    case addToCart
}

// MARK: - State
enum State: Equatable {
    case loading
    case showingProduct(AsyncResult<Product>)
    case showingAddedToCart(AsyncResult<Product>, AsyncResult<AddToCartResult>)
    
    static func reduce(state: State, event: Event) -> State {
        switch event {
            
        case .loadProduct:
            let productResult = getProduct()
            return .showingProduct(productResult)
            
        case .addToCart:
            
            var productResult: AsyncResult<Product>? {
                switch state {
                case let .showingProduct(product): return product
                case let .showingAddedToCart(product, _): return product
                default: return nil
                }
            }
            
            guard let product = productResult else { preconditionFailure() }
            
            let addToCartResult = addToCart(product)
            return .showingAddedToCart(product, addToCartResult)
        }
    }
    
}

func getProduct() -> AsyncResult<Product> {
    let promise = Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            seal.fulfill("Yeezy 500")
        }
    }
    return AsyncResult<Product>(promise)
}

// It returns error randomly
func addToCart(_ productResult: AsyncResult<Product>) -> AsyncResult<AddToCartResult> {
    
    return productResult.flatMap { (product: Product) -> AsyncResult<AddToCartResult> in
        
        let promise = Promise<Product> { seal in
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
        return AsyncResult<Product>(promise)
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
            initialState: State.loading,
            reducer: State.reduce,
            uiBindings: [view.updateUI],
            actions: actions
        )
    }
    
}
