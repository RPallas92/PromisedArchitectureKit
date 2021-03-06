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

typealias CartResponse = String
typealias User = String

struct Product: Equatable {
    let title: String
    let description: String
    let imageUrl: String
}

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
    case start
    case loading
    case productLoaded(Product)
    case addedToCart(Product, CartResponse)
    case error(Error)
    
    static func reduce(state: State, event: Event) -> Promise<State> {
        switch event {

        case .loadProduct:
            let productPromise = getProduct(cached: false)
            
            return productPromise
                .map { State.productLoaded($0) }
                .stateWhenLoading(State.loading)
                .mapErrorRecover { State.error($0) }
            
        case .addToCart:
            let productPromise = getProduct(cached: true)
            let userPromise = getUser()
            
            return Promise<(Product, User)>.zip(productPromise, userPromise).flatMap { pair -> Promise<State> in
                let (product, user) = pair
                
                return addToCart(product: product, user: user)
                    .map { State.addedToCart(product, $0) }
                    .mapErrorRecover{ State.error($0) }
            }
            .stateWhenLoading(State.loading)
        }
    }
}

fileprivate func getProduct(cached: Bool) -> Promise<Product> {
    let delay: DispatchTime = cached ? .now() : .now() + 3
    let product = Product(
        title: "Yeezy Triple White",
        description: "YEEZY Boost 350 V2 “Triple White,” aka “Cream”. \n adidas Originals has officially announced its largest-ever YEEZY Boost 350 V2 release. The “Triple White” iteration of one of Kanye West’s most popular silhouettes will drop again on September 21 for a retail price of $220. The sneaker previously dropped under the “Cream” alias.",
        imageUrl: "https://static.highsnobiety.com/wp-content/uploads/2018/08/20172554/adidas-originals-yeezy-boost-350-v2-triple-white-release-date-price-02.jpg")
    
    return Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: delay) {
            seal.fulfill(product)
        }
    }
}

fileprivate func addToCart(product: Product, user: User) -> Promise<CartResponse> {
    let randomNumber = Int.random(in: 1..<10)

    let failedPromise = Promise<CartResponse>(error: NSError(domain: "Error adding to cart",code: 15, userInfo: nil))
    let promise = Promise<CartResponse>.value("Product: \(product.title) added to cart for user: \(user)")

    if randomNumber < 5 {
        return failedPromise
    } else {
        return promise
    }
}

fileprivate func getUser() -> Promise<User> {
    return Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            seal.fulfill("Richi")
        }
    }

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
            initialState: State.start,
            reducer: State.reduce,
            uiBindings: [ { [weak self] state in
                self?.view?.updateUI(state: state)
            }]
        )
    }
}
