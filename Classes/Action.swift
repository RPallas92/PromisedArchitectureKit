//
//  Action.swift
//  PromisedArchitectureKit
//
//  Created by Pallas, Ricardo on 7/3/18.
//

import Foundation
import UIKit
import PromiseKit

public class Action<State,Event> {
    var listeners = [System<State, Event>]()

    func addListener(listener: System<State, Event>) {
        listeners.append(listener)
    }
    
    func notify(_ action: Event) {
        listeners.forEach { system in
            system.onAction(action)
        }
    }
}

public class CustomAction<State,Event>: Action<State, Event> {
    var event: Event
    
    public init(trigger event: Event) {
        self.event = event
    }
    
    public func execute() {
        let action = self.event
        notify(action)
    }
}

public class UIButtonAction<State,Event>: Action<State, Event> {
    
    var events = [UIControlEvents.RawValue: Event]()
    let button: UIButton
    
    private init(button: UIButton) {
        self.button = button
    }
    
    public static func onTap(in button: UIButton, trigger event: Event) -> UIButtonAction<State,Event> {
        let action = UIButtonAction(button: button)
        action.events[UIControlEvents.touchUpInside.rawValue] = event
        action.button.addTarget(self, action:#selector(self.didTap), for: .touchUpInside)
        return action
    }
    
    @objc func didTap() {
        guard let action = self.events[UIControlEvents.touchUpInside.rawValue] else {
            return
        }
        self.notify(action)
    }
}
