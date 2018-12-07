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
        disableBuyButton()
        cartLabel.text = "No products"
        errorLabel.text = ""
        
        
        switch state {
        case .loading:
            showLoading()
            
        case .productLoaded(let product):
            cartLabel.text = product
            hideLoading()
            
        case .error(let error):
            errorLabel.text = error.localizedDescription
            hideLoading()
            
        case .addedToCart(_, let cartResponse):
            cartLabel.text = cartResponse
            hideLoading()
            enableBuyButton()
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

