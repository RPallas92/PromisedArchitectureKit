//
//  ViewController.swift
//  PromisedArchitectureKit
//
//  Created by rpallas92 on 07/03/2018.
//  Copyright (c) 2018 rpallas92. All rights reserved.
//

import UIKit
import PromisedArchitectureKit

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

