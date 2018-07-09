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
    
    var presenter: Presenter! = nil
    var indicator: UIActivityIndicatorView! = nil
    var loadProductAction: CustomAction<State, Event>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLoadingIndicator()
        loadProductAction = CustomAction<State, Event>(trigger: Event.willLoadProduct)
        presenter = Presenter(view: self, actions: [loadProductAction])
        presenter.controllerLoaded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProductAction.execute()
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

        if case state = State.loading {
            showLoading()
        } else {
            hideLoading()
        }
        
        print(state)
    }
    
    private func showLoading() {
        indicator.startAnimating()
    }
    
    private func hideLoading() {
        indicator.stopAnimating()
    }

}

