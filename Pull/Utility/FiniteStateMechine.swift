//
//  FiniteStateMechine.swift
//  Pull
//
//  Created by leave on 21/01/2018.
//  Copyright © 2018 Gao. All rights reserved.
//

import Foundation


class FiniteStateMechine<StateType:Equatable, E> {

    enum ErrorType: Error {
        case wrongState
    }

    var currentState: StateType
    private let net: (_ event: E) -> (from:StateType, to:StateType)

    var willLeaveStateAction: ((FiniteStateMechine<StateType,E>, _ from: StateType, _ to: StateType) -> Void)?
    var didEnterStateAction: ((FiniteStateMechine<StateType,E>, _ from: StateType, _ to: StateType) -> Void)?


    init(initialState: StateType,
         transformer:@escaping (_ event: E) -> (from:StateType, to:StateType))
    {
        currentState = initialState
        net = transformer
    }

    func transitState(by event:E) throws {
        let e = net(event)
        guard currentState == e.from else {
            throw ErrorType.wrongState
        }
        let oldState = currentState
        let newState = e.to
        willLeaveStateAction?(self, oldState, newState)
        currentState = newState
        didEnterStateAction?(self, oldState, newState)
    }
}
