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

let mockProduct = "Yeezy 500"

// MARK: - Events
enum TestEvent {
    case loadProduct
}

// MARK: - State
enum TestState {
    case loading
    case showingProduct(Product)
    case showingError(Error)
    
    static func reduce(state: TestState, event: TestEvent) -> AsyncResult<TestState> {
        switch event {
        case .loadProduct:
            let productResult = getProduct()
            
            return productResult
                .map { TestState.showingProduct($0) }
                .stateWhenLoading(TestState.loading)
                .mapErrorRecover { TestState.showingError($0) }
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
    
    func testLoadProduct(){
        let expect = expectation(description: "testLoadProduct")
        
        func mockBinding(state : TestState) -> () {
            if case let .showingProduct(product) = state {
                XCTAssertEqual(product, mockProduct)
                expect.fulfill()
            }
        }
        
        let system = System<TestState, TestEvent>.pure(
            initialState: TestState.loading,
            reducer: TestState.reduce,
            uiBindings: [mockBinding]
        )
    
        system.sendEvent(.loadProduct)
        wait(for: [expect], timeout: 10.0)
    }
    
}
