//
//  PresenterTest.swift
//  PromisedArchitectureKit_Tests
//
//  Created by Pallas, Ricardo on 12/6/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest

class PresenterTest: XCTestCase {
    
    let expectedProduct = Product(
        title: "Yeezy Triple White",
        description: "YEEZY Boost 350 V2 “Triple White,” aka “Cream”. \n adidas Originals has officially announced its largest-ever YEEZY Boost 350 V2 release. The “Triple White” iteration of one of Kanye West’s most popular silhouettes will drop again on September 21 for a retail price of $220. The sneaker previously dropped under the “Cream” alias.",
        imageUrl: "https://static.highsnobiety.com/wp-content/uploads/2018/08/20172554/adidas-originals-yeezy-boost-350-v2-triple-white-release-date-price-02.jpg")
    
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
        
        let mockedView = ViewMock()
        mockedView.mockUpdateUI { state in
            if case let .productLoaded(product) = state {
                XCTAssertEqual(product, self.expectedProduct)
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

        let expectedResponse = "Product: Yeezy Triple White addded to cart for user: Richi"
        let expectedError = NSError(domain: "Error adding to cart",code: 15, userInfo: nil)
        
        let mockedView = ViewMock()
        mockedView.mockUpdateUI { state in
            if case let .addedToCart(product, cartResponse) = state {
                XCTAssertEqual(product, self.expectedProduct)
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
