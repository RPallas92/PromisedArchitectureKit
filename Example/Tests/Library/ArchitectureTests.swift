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

let mockProduct = Product(
    title: "Yeezy Triple White",
    description: "YEEZY Boost 350 V2 “Triple White,” aka “Cream”. \n adidas Originals has officially announced its largest-ever YEEZY Boost 350 V2 release. The “Triple White” iteration of one of Kanye West’s most popular silhouettes will drop again on September 21 for a retail price of $220. The sneaker previously dropped under the “Cream” alias.",
    imageUrl: "https://static.highsnobiety.com/wp-content/uploads/2018/08/20172554/adidas-originals-yeezy-boost-350-v2-triple-white-release-date-price-02.jpg")

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
