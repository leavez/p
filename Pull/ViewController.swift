//
//  ViewController.swift
//  Pull
//
//  Created by Gao on 9/11/17.
//  Copyright © 2017 Gao. All rights reserved.
//

import UIKit


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

protocol RefresherViewAdatpterProtocol {
    // in
    var pullingPercentage: SimpleSignal<Double> { get }
    var isDragging: Bool { get }
    // out
    func setScrollViewToPullingPercentage(_ percentage: Double)
    func setScrollViewToLoadingState(_ loading: Bool)
}


protocol RefresherCoreProtocol {
    func scrollViewDidChangePullingPercentage(_ percentage: Double)
    func stateWillChange(from: Refresher.State, to: Refresher.State)
    func stateDidChange(to: Refresher.State, from: Refresher.State)
}

class struct


struct Refresher {

    enum State {
        case normal, pulling, loading, shrinking
    }

    enum Event {
        case toPulling, backToNormal
        case toLoading, toShrinking, toNormal
    }

    class Manager {

        let state = FiniteStateMechine<State, Event>(initialState: State.normal) { s in
            switch s {
            case .toPulling:
                return (.normal, .pulling)
            case .toLoading:
                return (.pulling, .loading)
            case .toShrinking:
                return (.loading, .shrinking)
            case .toNormal:
                return (.shrinking, .normal)
            case .backToNormal :
                return (.pulling, .normal)
            }
        }

        let viewAdapter: ViewAdapter
        let core: RefresherCoreProtocol

        init(scrollView: UIScrollView, core: RefresherCoreProtocol) {
            viewAdapter = ViewAdapter(scrollView: scrollView, triggerDistance: 50)
            core =
            state.willLeaveStateAction = { [weak self] in self?.stateWillChange(from: $1, to: $2) }
            state.didEnterStateAction = { [weak self] in self?.stateDidChange(to: $2, from: $1) }
            viewAdapter.pullingPercentage.subscribe { [weak self] in self?.scrollViewDidChangePullingPercentage($0) }
        }


        // MARK:-

        func scrollViewDidChangePullingPercentage(_ percentage: Double) {
//            print("\(percentage)")
            switch state.currentState {
            case .normal:
                if percentage > 0 {
                    try! state.transitState(by: .toPulling)
                }
            case .pulling:
                if viewAdapter.isDragging == false, percentage > 1 {
                    try! state.transitState(by: .toLoading)
                } else if percentage <= 0 {
                    try! state.transitState(by: .backToNormal)
                }
            case .loading:
                ()
            case .shrinking:
                if percentage <= 0 {
                    try! state.transitState(by: .toNormal)
                }
            }
        }

        func stateWillChange(from: State, to: State) {
            print("\(from) -> \(to)")
        }

        func stateDidChange(to: State, from: State) {
            switch (from, to) {
            case (.pulling, .loading):
                UIView.animate(withDuration: 0.25, animations: {
                    UIView.setAnimationBeginsFromCurrentState(true)
//                    UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: 7)!)
                    self.viewAdapter.setScrollViewToLoadingState(true)
                    self.viewAdapter.setScrollViewToPullingPercentage(1)
                })
                // hack
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    try! self.state.transitState(by: .toShrinking)
                })
            case (.loading, .shrinking):
                UIView.animate(withDuration: 0.25, animations: {
                    self.viewAdapter.setScrollViewToLoadingState(false)
                    self.viewAdapter.setScrollViewToPullingPercentage(0)
                })
            //                viewAdapter.animateBackToNormal()
            default:
                ()
            }
        }

    }

    class ViewAdapter: RefresherViewAdatpterProtocol {


        var pullingPercentage = SimpleSignal<Double>(0)
        let triggerDistance: CGFloat
        var isDragging: Bool {
            return view?.isDragging ?? false
        }

         weak var view: UIScrollView?
        private var insetsAlreadyAdded = false
        private var dispose: NSKeyValueObservation?

        init(scrollView:UIScrollView, triggerDistance: CGFloat) {
            view = scrollView
            self.triggerDistance = triggerDistance
            dispose = scrollView.observe(\UIScrollView.contentOffset, options: [ .new]) {
                [weak self] (scrollView, offset) in
                guard let sself = self, let offsetY = offset.newValue?.y else { return }
                sself.pullingPercentage.value = sself.percentage(from: offsetY)
//                print("\(offsetY)")
            }
        }

        func setScrollViewToPullingPercentage(_ percentage: Double) {
            guard let view = view else { return }
            let offset = view.contentOffset
            view.contentOffset = CGPoint(x: offset.x, y: self.offset(from: percentage))
        }

        func setScrollViewToLoadingState(_ loading: Bool) {
            guard let view = view else { return }
            guard loading != insetsAlreadyAdded else { return }
            insetsAlreadyAdded = loading
            let delta = triggerDistance * (loading ? 1 : -1)


            var insets = view.contentInset
            insets.top += delta
            view.contentInset = insets

//            // make up the offset
//            var offset = view.contentOffset
//            offset.y += delta
//            view.contentOffset = offset
        }


        private func percentage(from offset:CGFloat) -> Double {
            guard offset < 0 else { return 0 }
            return Double( abs(offset) / triggerDistance )
        }
        private func offset(from percentage: Double) -> CGFloat {
            guard percentage > 0 else { return 0 }
            return -1 * ( CGFloat(percentage) * triggerDistance )
        }
    }
}




class ViewController: UIViewController, UIScrollViewDelegate {
    let scrollView = UIScrollView()
    var manager: Refresher.Manager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(scrollView)
        var frame = self.view.bounds
        frame.origin.y = 20
        frame.size.height -= 20
        scrollView.frame = frame
        scrollView.backgroundColor = UIColor.brown
        scrollView.contentSize = CGSize(width: 100, height: 100000)
        scrollView.contentInset = .zero

        let v = UIView(frame: CGRect(x: 20, y: 0, width: 200, height: 80))
        v.backgroundColor = UIColor.orange
        scrollView.addSubview(v)

        manager = Refresher.Manager(scrollView: scrollView)

    }
}

