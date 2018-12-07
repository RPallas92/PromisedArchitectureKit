//
//  PresenterTest.swift
//  PromisedArchitectureKit_Tests
//
//  Created by Pallas, Ricardo on 12/6/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest

class PresenterTest: XCTestCase {
    
    class ViewMock: View {
        var updateUIFunction: ((State) -> ())?
        
        func updateUI(state: State)  {
            updateUIFunction?(state)
        }
        
        func mockUpdateUI(_ mockFunction: @escaping (State) -> ()) {
            self.updateUIFunction = mockFunction
        }
    }
    
    func testLoadProduct() {
        let expect = expectation(description: "testLoadProduct")
        let expectedProduct = "Yeezy 500"
        
        let mockedView = ViewMock()
        mockedView.mockUpdateUI { state in
            if case let .productLoaded(product) = state {
                XCTAssertEqual(product, expectedProduct)
                expect.fulfill()
            }
        }
        let presenter = Presenter(view: mockedView)
        presenter.controllerLoaded()
        presenter.sendEvent(.loadProduct)
        
        wait(for: [expect], timeout: 10.0)
    }
    
    func testAddToCart() {
        let expect = expectation(description: "testAddToCart")
        let expectedProduct = "Yeezy 500"
        let expectedResponse = "Product: Yeezy 500 addded to cart for user: Richi"
        let expectedError = NSError(domain: "Error adding to cart",code: 15, userInfo: nil)

        let mockedView = ViewMock()
        mockedView.mockUpdateUI { state in
            if case let .addedToCart(product, cartResponse) = state {
                XCTAssertEqual(product, expectedProduct)
                XCTAssertEqual(cartResponse, expectedResponse)
                expect.fulfill()
            } else if case let .error(error) = state {
                let error = error as NSError
                XCTAssertEqual(error, expectedError)
                expect.fulfill()
            }
        }
        
        let presenter = Presenter(view: mockedView)
        presenter.controllerLoaded()
        presenter.sendEvent(.addToCart)
        
        wait(for: [expect], timeout: 10.0)
    }

    
}
