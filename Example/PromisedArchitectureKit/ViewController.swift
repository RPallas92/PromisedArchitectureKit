//
//  ViewController.swift
//  PromisedArchitectureKit
//
//  Created by rpallas92 on 07/03/2018.
//  Copyright (c) 2018 rpallas92. All rights reserved.
//

import UIKit

class ViewController: UIViewController, View {
    
    var presenter: Presenter! = nil
    var indicator: UIActivityIndicatorView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addLoadingIndicator()
        presenter = Presenter(view: self)
        
        presenter.controllerLoaded()
    }
    
    private func addLoadingIndicator() {
        indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        indicator.center = view.center
        self.view.addSubview(indicator)
        self.view.bringSubview(toFront: indicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func updateUI(state: State) {
        
        if state.dataState == .loading {
            showLoading()
        } else {
            hideLoading()
        }
    }
    
    private func showLoading() {
        indicator.startAnimating()
    }
    
    private func hideLoading() {
        indicator.stopAnimating()
    }

}

