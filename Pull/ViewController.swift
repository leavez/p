//
//  ViewController.swift
//  Pull
//
//  Created by Gao on 9/11/17.
//  Copyright © 2017 Gao. All rights reserved.
//

import UIKit





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

        init(scrollView: UIScrollView) {
            viewAdapter = ViewAdapter(scrollView: scrollView, triggerDistance: 50)
            core = NativeCore(viewAdapter: viewAdapter, state: state)
            state.willLeaveStateAction = { [weak self] in self?.core.stateWillChange(from: $1, to: $2) }
            state.didEnterStateAction = { [weak self] in self?.core.stateDidChange(to: $2, from: $1) }
            viewAdapter.pullingPercentage.subscribe { [weak self] in self?.core.scrollViewDidChangePullingPercentage($0) }
        }


        // MARK:-


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

        let v = UIView(frame: CGRect(x: 20, y: 0, width: 300, height: 80))
        v.backgroundColor = UIColor.orange
        scrollView.addSubview(v)

        manager = Refresher.Manager(scrollView: scrollView)

    }
}

