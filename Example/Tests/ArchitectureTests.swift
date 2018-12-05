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

typealias Product = String

let mockProduct = "Yeezy 500"

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
                .stateWhenLoading(State.loading)
                .mapErrorRecover { State.showingError($0) }
        }
    }
}

func getProduct() -> AsyncResult<Product> {
    let promise = Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            seal.fulfill(mockProduct)
        }
    }
    
    return AsyncResult<Product>(promise)
}


class ArchitectureKitTests: XCTestCase {
    
    func testArchitecture(){
        let expect = expectation(description: "testArchitecture")
        
        func mockBinding(state : State) -> () {
            guard case let .showingProduct(product) = state else { return }
            XCTAssertEqual(product, mockProduct)
            expect.fulfill()
        }

        let system = System<State, Event>.pure(
            initialState: State.loading,
            reducer: State.reduce,
            uiBindings: [mockBinding]
        )
    
        system.sendEvent(.loadProduct)
        wait(for: [expect], timeout: 10.0)
    }
    
}
