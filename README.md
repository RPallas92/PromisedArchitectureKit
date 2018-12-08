# PromisedArchitectureKit V2

[![CI Status](https://img.shields.io/travis/rpallas92/PromisedArchitectureKit.svg?style=flat)](https://travis-ci.org/rpallas92/PromisedArchitectureKit)
[![Version](https://img.shields.io/cocoapods/v/PromisedArchitectureKit.svg?style=flat)](https://cocoapods.org/pods/PromisedArchitectureKit)
[![License](https://img.shields.io/cocoapods/l/PromisedArchitectureKit.svg?style=flat)](https://cocoapods.org/pods/PromisedArchitectureKit)
[![Platform](https://img.shields.io/cocoapods/p/PromisedArchitectureKit.svg?style=flat)](https://cocoapods.org/pods/PromisedArchitectureKit)


The simplest architecture for [PromiseKit](https://github.com/mxcl/PromiseKit), now V2, even simpler and easier to reason about.

### V2 Goal

> PromisedArchitectureKit V2 has been designed to impose constraints that enforce correctness and simplicity.
  
## Introduction

PromisedArchitectureKit is a library that tries to enforce correctness and simplify the state management of applications and systems. It helps you write applications that behave consistently, and are easy to test. It’s inspired by Redux and RxFeedback.

## Motivation

I have been trying to find a proper way and architecture to simplify the complexity of managing and handling the state of mobile applications, and also, easy to test.


I started with **Model-View-Controller (MVC)**, then **Model-View-ViewModel (MVVM)** and also Model-View-Presenter (MVP) along with Clean architecture. MVC is not as easy to test as in MVVM and MVP. MVVM and MVP are easy to test, but the issue is the UI state can be a mess, since there is not a centralized way to update it, and you can have lots of methods among the code that changes the state.


Then it appeared **Elm** and **Redux** and other Redux-like architectures as Redux-Observable, RxFeedback, Cycle.js, ReSwift, etc. The main difference between these architectures (including PromisedArchitectureKit) and MVP is that they introduce constrains of how the UI state can be updated, in order to enforce correctness and make apps easier to reason about.  


Which make PromisedArchitectureKit different from these Redux-like architectures is it uses
async reducers (using PromiseKit) to wrap the effects, then it runs side effects for you and calls the UI with the result.

**PromisedArchitectureKit runs side effects for you. Your code stays 100% pure.**


## Quick start

### Installation

PromisedArchitectureKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PromisedArchitectureKit'
```

## PromisedArchitectureKit
PromisedArchitectureKit itself is very simple. How it looks:

```swift
self.system = System.pure(
	initialState: State.start,
   	reducer: State.reduce,
   	uiBindings: [view?.updateUI]
)
```

### The core concept
Each screen of your app (and the whole app) has a state itself. in PromisedArchitectureKit, this state is represented as an Enum. For example, the state of a Ecommerce **Product detail page (PDP)** app might look like this:

```swift
enum State {
    case start
    case loading
    case productLoaded(Product)
    case addedToCart(Product, CartResponse)
    case error(Error)
}
```
In this screen, the app loads the product, then it can show the product or an error. After the product is loaded, the user can add it to the basket.  

This State enum, representes the state of the **“PDP screen”** in the ecommerce app.
With this approach of having an enum that actually represents the state of a screen, views are a direct mapping of state:  

`view = f(state)`. 

That “f” function will be the UI binding function that we will see later on.

**To change something in the state, you need to dispatch an Event.** An event is an enum that describes what happened. Here are a few example events:

```swift
enum Event {
    case loadProduct
    case addToCart
}
```

Enforcing that every change is described as an event lets us have a clear understanding of what’s going on in the app. If something changed, we know why it changed.  

 Events are like breadcrumbs of what has happened. Finally, to tie state and actions together, we write a function called **reducer**. A reducer it’s just a function that **takes state and action as arguments, and returns the next state of the app (asynchronously)**:
 
`(State, Event) -> AsyncResult<State>`

AsyncResult is just a wrapper of Promise.  

We write a reducer function for every state of every screen. For the PDP screen:  
 
 
 ```swift
    static func reduce(state: State, event: Event) -> AsyncResult<State> {
        switch event {

        case .loadProduct:
            let productResult = getProduct(cached: false)
            
            return productResult
                .map { State.productLoaded($0) }
                .stateWhenLoading(State.loading)
                .mapErrorRecover { State.error($0) }
            
        case .addToCart:
            let productResult = getProduct(cached: true)
            let userResult = getUser()
            
            return AsyncResult<(Product, User)>.zip(productResult, userResult).flatMap { pair -> AsyncResult<State> in
                let (product, user) = pair
                
                return addToCart(product: product, user: user)
                    .map { State.addedToCart(product, $0) }
                    .mapErrorRecover{ State.error($0) }
            }
            .stateWhenLoading(State.loading)
        }
    }
 ```

Notice that the reducer is a pure function, in terms of referencial transparency, and for state S and event E, it always return the same state description, and has no side effects (it only returns descriptions of the effects, the library will run them for you).


**This is basically the whole idea of PromisedArchitectureKit**. Note that we haven’t used any PromisedArchitectureKit APIs. It comes with a few utilities to facilitate this pattern, but the main idea is that you describe how your state is updated over time in response to events, and 90% of the code you write is just plain Swift, so the UI logic can be tested with ease.

But what about asynchronous code and side effects as API calls, DB calls, logging, reading and writing files?

### Using PromiseKit as a time abstraction

A Promise is used for handling asynchronous operations. PromisedArchitectureKit uses them in order to trigger reactions to some states. Example of Promise:

```swift 

    func getProduct() -> Promise<Product> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                seal.fulfill("Yeezy 500")
            }
        }
    }

```

That function returns a Promise that will return a product. It waits for 5 seconds and then returns the product. It simulates a network call.

### Don't fear the AsyncResult
AsyncResult is just a wrapper over Promise that provides it more power. It is just like a Promise on steroids.

But don't worry. If you whole app uses Promises, it is ok. You can keep using promises and transform them to AsyncResults on the reducer function with ease.

How to get an AsyncResult from a Promise?:

```
let asyncResult = AsyncResult(promise)
```

And that's it!

### What if i want to make network calls, DB calls, and so on?

If we want to load the product from the backend, we would require a network call, which is a side effect and it is asynchronous.

In order to achieve it, we will use Promises to handle async code. As the reducer funciton returns the new state async, we can map Promises to new states.

For example, we are in Start state, and we want to load a product and go to loadedProduct state, when a loadProduct event is triggered. In the reducer we do:

```swift 
    static func reduce(state: State, event: Event) -> AsyncResult<State> {
        switch event {

        case .loadProduct:
            let productResult = getProduct(cached: false)
            
            return productResult
                .map { State.productLoaded($0) }
                .stateWhenLoading(State.loading)
                .mapErrorRecover { State.error($0) }
                
        (...)

```

What is this doing? Step by step:

* When a loadProduct event is triggered

```swift
	switch event {
   		case .loadProduct:
```
* We get the product (AsyncResult<Product>)

```swift
	let productResult = getProduct(cached: false)
``` 

* In case of the product would be retrieved successfully we will return a loadedProduct state:

```swift
return productResult
 	.map { State.productLoaded($0) }

```

* We want to send the UI a loading state while the Promise being executed until it gets resolved, so the UI can show a loading indicator:

```swift
.stateWhenLoading(State.loading)
```

* In case of the product **wouldn't** be retrieved successfully we will return a error state:

```swift
	.mapErrorRecover { State.error($0) }

```

Pretty easy and neat.

**There is no side effect here: there is only a description of it. Actually, the side effect will be executed by the library.**

### Update the view

After a new state change, the View's updateUI function will be called with the new state. Then the view is in charge of update its ui components.
 
Example:

```swift
    func updateUI(state: State) {
        showLoading()
        addToCartButton.isEnabled = false
        refreshButton.isHidden = false

    
        switch state {
        case .start:
            productTitleLabel.text = ""
            descriptionLabel.text = ""
            imageView.image = nil
        case .loading:
            refreshButton.isHidden = true
            showLoading()
            
        case .productLoaded(let product):
            productTitleLabel.text = product.title
            descriptionLabel.text = product.description
            updateImage(with: product.imageUrl)
            addToCartButton.isEnabled = true
            hideLoading()
            
        case .error(let error):
            descriptionLabel.text = error.localizedDescription
            hideLoading()
            
        case .addedToCart(_, let cartResponse):
            hideLoading()
            addToCartButton.isEnabled = true
            showAddedToCartAlert(cartResponse)
        }

        print(state)
    }
```

So, the presenter will compute the next state, and will send it to the view. The view will draw itself accordingly.  


## What the library does under the hood?

TODO: Explain a whole loop, step by step

## Why should I use PromisedArchiterueKit V2 ?
TODO: explain why

explaing main advantages (what it does - telegram chat)  
explain analytics


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

ViewController's code:

```swift
class ViewController: UIViewController, View {
    
    @IBOutlet weak var productTitleLabel: UILabel!
    @IBOutlet weak var cartLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    
    var presenter: Presenter! = nil
    var indicator: UIActivityIndicatorView! = nil
    var loadProductAction: CustomAction<State, Event>! = nil
    var addToCartAction: CustomAction<State, Event>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLoadingIndicator()
        initActions()
        
        presenter = Presenter(view: self, actions: [loadProductAction, addToCartAction])
        presenter.controllerLoaded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProductAction.execute()
    }
    
    private func initActions() {
        loadProductAction = CustomAction<State, Event>(trigger: Event.willLoadProduct)
        addToCartAction = CustomAction<State, Event>(trigger: Event.willAddToCart)
    }
    
    private func addLoadingIndicator() {
        indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        indicator.center = view.center
        self.view.addSubview(indicator)
        self.view.bringSubview(toFront: indicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // MARK: - User Actions
    @IBAction func didTapRefresh(_ sender: Any) {
        loadProductAction.execute()
    }
    
    @IBAction func didTapAddToCart(_ sender: Any) {
        addToCartAction.execute()
    }

    // MARK: - User Outputs
    func updateUI(state: State) {
        hideLoading()
        disableBuyButton()
        cartLabel.text = "No products"

        switch state {
        case .start:
            print("Starting")
            disableBuyButton()
            
        case .loading:
            showLoading()
            
        case .showProduct(let product):
            productTitleLabel.text = product
            
        case .addingToCart(_):
            showLoading()
            
        case .showProductDidAddToCart(let product):
            cartLabel.text = product
            enableBuyButton()

        case .showError(let errorDescription):
            errorLabel.text = errorDescription
        }
        
        print(state)
    }
    
    private func enableBuyButton() {
        buyButton.alpha = 1.0
        buyButton.isEnabled = true
    }
    
    private func disableBuyButton() {
        buyButton.alpha = 0.30
        buyButton.isEnabled = false
    }
    
    private func showLoading() {
        indicator.startAnimating()
    }
    
    private func hideLoading() {
        indicator.stopAnimating()
    }

}
```


Prenseter's code:

```swift
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

```


## Author

Ricardo Pallás

## License

PromisedArchitectureKit is available under the MIT license. See the LICENSE file for more info.

### TO DO
Explain changes between V1 and V2
