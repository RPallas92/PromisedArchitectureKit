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

