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
typealias CartResponse = String
typealias User = String

protocol View: class {
    func updateUI(state: State)
}

// MARK: - Events
enum Event {
    case loadProduct
    case addToCart
}

// MARK: - State
enum State {
    case loading
    case showingProduct(Product)
    case showingAddedToCart(Product, CartResponse)
    case showingError(Error)
    
    static func reduce(state: State, event: Event) -> AsyncResult<State> {
        switch event {
            
        case .loadProduct:
            let productResult = getProduct(cached: false)
            
            return productResult
                .map { State.showingProduct($0) }
                .stateWhenLoading(State.loading)
                .mapErrorRecover { State.showingError($0) }
            
        case .addToCart:
            let productResult = getProduct(cached: true)
            let userResult = getUser()
            
            return AsyncResult<(Product, User)>.zip(productResult, userResult).flatMap { pair -> AsyncResult<State> in
                let (product, user) = pair
                
                return addToCart(product: product, user: user)
                    .map { State.showingAddedToCart(product, $0) }
                    .mapErrorRecover{ State.showingError($0) }
            }
            .stateWhenLoading(State.loading)

            
        }
    }
}


fileprivate func getProduct(cached: Bool) -> AsyncResult<Product> {
    let delay: DispatchTime = cached ? .now() : .now() + 3
    let promise = Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: delay) {
            seal.fulfill("Yeezy 500")
        }
    }
    
    return AsyncResult<Product>(promise)
}


fileprivate func addToCart(product: Product, user: User) -> AsyncResult<CartResponse> {
    let randomNumber = Int.random(in: 1..<10)
    
    let failedPromise = Promise<CartResponse>(error: NSError(domain: "Error adding to cart",code: 15, userInfo: nil))
    let promise = Promise<CartResponse>.value("Product: \(product) addded to cart for user: \(user)")
    
    if randomNumber < 5 {
        return AsyncResult<CartResponse>(failedPromise)
    } else {
        return AsyncResult<CartResponse>(promise)
    }
}

fileprivate func getUser() -> AsyncResult<User> {
    let promise = Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            seal.fulfill("Richi")
        }
    }
    
    return AsyncResult<User>(promise)
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
