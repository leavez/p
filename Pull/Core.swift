//
//  Core.swift
//  Pull
//
//  Created by leave on 17/09/2017.
//  Copyright © 2017 Gao. All rights reserved.
//

import UIKit


struct NormalCore: RefresherCoreProtocol {

    let viewAdapter: RefresherViewAdatpterProtocol
    unowned let state: FiniteStateMechine<Refresher.State, Refresher.Event>

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

    func stateWillChange(from: Refresher.State, to: Refresher.State) {
        print("\(from) -> \(to)")
    }

    func stateDidChange(to: Refresher.State, from: Refresher.State) {
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

struct SmoothCore: RefresherCoreProtocol {

    let viewAdapter: RefresherViewAdatpterProtocol
    unowned let state: FiniteStateMechine<Refresher.State, Refresher.Event>

    func scrollViewDidChangePullingPercentage(_ percentage: Double) {
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

    func stateWillChange(from: Refresher.State, to: Refresher.State) {
        print("\(from) -> \(to)")
    }

    func stateDidChange(to: Refresher.State, from: Refresher.State) {
        switch (from, to) {
        case (.pulling, .loading):
            UIView.animate(withDuration: 0.5, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: 7)!)
                self.viewAdapter.setScrollViewToLoadingState(true)
                self.viewAdapter.setScrollViewToPullingPercentage(1)
            }, completion: nil)
            // hack
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                try! self.state.transitState(by: .toShrinking)
            })
        case (.loading, .shrinking):
            UIView.animate(withDuration: 0.17, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.viewAdapter.setScrollViewToLoadingState(false)
                self.viewAdapter.setScrollViewToPullingPercentage(0)
            }, completion: nil)
        default:
            ()
        }
    }
}


struct NativeCore: RefresherCoreProtocol {

    let viewAdapter: RefresherViewAdatpterProtocol
    unowned let state: FiniteStateMechine<Refresher.State, Refresher.Event>

    func scrollViewDidChangePullingPercentage(_ percentage: Double) {
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

    func stateWillChange(from: Refresher.State, to: Refresher.State) {
        print("\(from) -> \(to)")
    }

    func stateDidChange(to: Refresher.State, from: Refresher.State) {
        switch (from, to) {
        case (.pulling, .loading):
            UIView.animate(withDuration: 0.5, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: 7)!)
                self.viewAdapter.setScrollViewToLoadingState(true)
                self.viewAdapter.setScrollViewToPullingPercentage(1)
            }, completion: nil)
            // hack
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                try! self.state.transitState(by: .toShrinking)
            })
        case (.loading, .shrinking):
            UIView.animate(withDuration: 0.17, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.viewAdapter.setScrollViewToLoadingState(false)
                self.viewAdapter.setScrollViewToPullingPercentage(0)
            }, completion: nil)
        default:
            ()
        }
    }
}
