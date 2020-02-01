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
   	uiBindings: [ { [weak self] state in
    	self?.view?.updateUI(state: state)
    }]
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
 
`(State, Event) -> Promise<State>`

We write a reducer function for every state of every screen. For the PDP screen:  
 
 
 ```swift
    static func reduce(state: State, event: Event) -> Promise<State> {
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
            
            return Promise<(Product, User)>.zip(productResult, userResult).flatMap { pair -> Promise<State> in
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

### What if i want to make network calls, DB calls, and so on?

If we want to load the product from the backend, we would require a network call, which is a side effect and it is asynchronous.

In order to achieve it, we will use Promises to handle async code. As the reducer funciton returns the new state async, we can map Promises to new states.

For example, we are in Start state, and we want to load a product and go to loadedProduct state, when a loadProduct event is triggered. In the reducer we do:

```swift 
    static func reduce(state: State, event: Event) -> Promise<State> {
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
* We get the product (Promise<Product>)

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

**Warning:**

**Always pass the update UI function to the System as a function that does not retain the view. Otherwise you will have a memory leak.
In the examples, we send the view's updateUI using weak self.**


## What the library does under the hood?
The library's core is small. It can be pasted here:

```swift
//
//  System.swift
//  PromisedArchitectureKit
//
//  Created by Pallas, Ricardo on 7/3/18.
//

import Foundation
import PromiseKit

public final class System<State, Event> {

    internal var eventQueue = [Event]()
    internal var callback: ((State, [State]) -> ())? = nil

    internal var initialState: State
    internal var reducer: (State, Event) -> Promise<State>
    internal var uiBindings: [((State) -> ())?]
    internal var currentState: State
    internal var historyOfStates: [State] = []

    private init(
        initialState: State,
        reducer: @escaping (State, Event) -> Promise<State>,
        uiBindings: [((State) -> ())?]
        ) {
        self.initialState = initialState
        self.reducer = reducer
        self.uiBindings = uiBindings
        self.currentState = initialState
    }

    public static func pure(
        initialState: State,
        reducer: @escaping (State, Event) -> Promise<State>,
        uiBindings: [((State) -> ())?]
        ) -> System {
        
        let system = System<State,Event>(initialState: initialState, reducer: reducer, uiBindings: uiBindings)
        system.historyOfStates.append(initialState)
        system.bindUI(initialState)
        return system
    }

    public func addLoopCallback(callback: @escaping (State, [State])->()){
        self.callback = callback
    }

    var actionExecuting = false

    public func sendEvent(_ action: Event) {
        assert(Thread.isMainThread)
        if actionExecuting {
            self.eventQueue.append(action)
        } else {
            actionExecuting = true
            let _ = doLoop(action).done { state in
                self.actionExecuting = false
                if let nextEvent = self.eventQueue.first {
                    self.eventQueue.removeFirst()
                    self.sendEvent(nextEvent)
                }
            }
        }
    }

    private func doLoop(_ event: Event) -> Promise<State> {
        return Promise.value(event)
            .then { event -> Promise<State> in
                
                let statePromise = self.reducer(self.currentState, event)

                if let stateWhenLoading = statePromise.loadingState {
                    self.historyOfStates.append(stateWhenLoading)
                    self.bindUI(stateWhenLoading)
                }

                return statePromise
            }
            .map { state in
                self.currentState = state
                self.historyOfStates.append(state)
                self.bindUI(state)
                return state
            }
    }

    private func bindUI(_ state: State) {
        self.uiBindings.forEach { uiBinding in
            uiBinding?(state)
        }
        self.callback?(state, self.historyOfStates)
    }
}


```

It executes loops on the `doLoop` function. What is a loop?
It is the whole cycle where and event is triggered, a new state is calculated and the UI is updated accordingly.

Following the load product example:

1. A `loadProduct` event is sent by the view. The `sendEvent` function is called that calls the `doLoop` function.

2. The `doLoop` function executed the side effects thrown by the reducer and gets the new state async. If a loading state was specified it notifies the UI before running the side effects. After that, it updates the current state and calls the UI with the new state.

**To sum up: The system listens to events, runs side effects to get the new state and notifies the UI that the state has changed.**

## Why should I use PromisedArchiterueKit V2 ?

As said before, the goal of the library is to put constraints to enforce correcness and make architecure easier to read and easier to reason about. These contraints are: there a finite number of states for each screen, there are a finite number of events that can change the state, and the library decides when to update the UI.

Those restrictions comes with advantages, the trade off is worth it. 
The main advantages the library provides are: 

* The library executes **all side effects for you** so your code stays pure.
* It updates the view when needed, you don't need to take care.
* You can know what the screen is about, reading the State enum.
* You know in compile-time that your view handles are states.
* You know what actions can be done on the screen, reading the Event enum.
* You know that all events are handled by the presenter on compile time.
* A single function will be called on every state change. That can be useful to have good analytics, for example. 

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

ViewController's code:

```swift
import UIKit
import PromisedArchitectureKit

class ViewController: UIViewController, View {
    
    @IBOutlet weak var productTitleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addToCartButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    var presenter: Presenter! = nil
    var indicator: UIActivityIndicatorView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLoadingIndicator()
        
        presenter = Presenter(view: self)
        presenter.controllerLoaded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.sendEvent(Event.loadProduct)
    }
    
    private func addLoadingIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        indicator.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        indicator.center = view.center
        view.addSubview(indicator)
        view.bringSubviewToFront(indicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // MARK: - User Actions
    @IBAction func didTapRefresh(_ sender: Any) {
        presenter.sendEvent(Event.loadProduct)
    }
    
    @IBAction func didTapAddToCart(_ sender: Any) {
        presenter.sendEvent(Event.addToCart)
    }

    // MARK: - User Outputs
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
    
    private func showLoading() {
        indicator.startAnimating()
    }
    
    private func hideLoading() {
        indicator.stopAnimating()
    }
    
    private func showAddedToCartAlert(_ message: String) {
        let alertController = UIAlertController(title: "Added to cart", message:
            message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func updateImage(with urlPath: String) {
        if let url = URL(string: urlPath), let data = try? Data(contentsOf: url) {
            let image = UIImage(data: data)
            imageView.image = image
        }
    }

}
```


Prenseter's code:

```swift
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
            let productResult = getProduct(cached: false)
            
            return productResult
                .map { State.productLoaded($0) }
                .stateWhenLoading(State.loading)
                .mapErrorRecover { State.error($0) }
            
        case .addToCart:
            let productResult = getProduct(cached: true)
            let userResult = getUser()
            
            return Promise<(Product, User)>.zip(productResult, userResult).flatMap { pair -> Promise<State> in
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
    
    let promise = Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: delay) {
            seal.fulfill(product)
        }
    }

    return Promise<Product>(promise)
}

fileprivate func addToCart(product: Product, user: User) -> Promise<CartResponse> {
    let randomNumber = Int.random(in: 1..<10)

    let failedPromise = Promise<CartResponse>(error: NSError(domain: "Error adding to cart",code: 15, userInfo: nil))
    let promise = Promise<CartResponse>.value("Product: \(product.title) added to cart for user: \(user)")

    if randomNumber < 5 {
        return Promise<CartResponse>(failedPromise)
    } else {
        return Promise<CartResponse>(promise)
    }
}

fileprivate func getUser() -> Promise<User> {
    let promise = Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            seal.fulfill("Richi")
        }
    }

    return Promise<User>(promise)
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

```

## Bonus: analytics
In case you want to add analytics to your app, you will end up having lots of calls to some `TrackingService.trackEvent` method among the code. Which, sometimes, can become an mess.

Luckily, PromisedArchitectureKit, includes the "addLoopCallback(callback: @escaping (State)->())" function, that will be called every time a state change occurs. The function receives the new state as a parameter, which can be use for analytics.

### Analytics Example

```swift
func handleAnalitycs(state: State) {
    switch state {
    case .start:
        EventTracker.trackEvent(event: .pdpShown)
        
    case .loading:
        EventTracker.trackEvent(event: .pdpLoading)

    case .productLoaded(let product):
        EventTracker.trackEvent(event: .productLoaded, attr: product)

    case .error(let error):
        EventTracker.trackEvent(event: .pdpError, attr: error)

        
    case .addedToCart(let product, _):
        EventTracker.trackEvent(event: .pdpAddedToCart, attr: product)

    }
}

func controllerLoaded() {
    system = System.pure(
        initialState: State.start,
        reducer: State.reduce,
        uiBindings: [ { [weak self] state in
					self?.view?.updateUI(state: state)
				}]
    )
        
    system?.addLoopCallback(callback: handleAnalytics)
}
    
```

By adding the `handleAnalytics` method as a system's loop callback, we have all analytics in the same place, centralized.



 

Disclaimer: This will only work with analytics related to logic. If you need to track things like "User did scroll", you will need to do it the same way as without the library.


## Author

Ricardo Pallás

## License

PromisedArchitectureKit is available under the MIT license. See the LICENSE file for more info.
