//
//  Signal.swift
//  Pull
//
//  Created by leave on 21/01/2018.
//  Copyright © 2018 Gao. All rights reserved.
//

import Foundation

/// A simple implementation of signal who can perform subscribe action
class SimpleSignal<T> {

    var value: T {
        didSet { subscribeAction.forEach{ $0(value) } }
    }

    private var subscribeAction: [(T) -> Void] = []

    init(_ value:T) {
        self.value = value
    }

    func subscribe(_ action:@escaping (_ value:T)->Void ) {
        subscribeAction.append(action)
    }
}
