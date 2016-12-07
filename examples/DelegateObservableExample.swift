/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import IndefiniteObservable

// This example demonstrates how to observe state changes from a delegate. We use
// UIPanGestureRecognizer in this example, but the Producer pattern can be used for any delegated
// type.

class DragProducer: Subscription {
  typealias Value = (state: UIGestureRecognizerState, location: CGPoint)

  init(subscribedTo gesture: UIPanGestureRecognizer, observer: ValueObserver<Value>) {
    self.gesture = gesture
    self.observer = observer

    gesture.addTarget(self, action: #selector(didPan))

    // Populate the observer with the current gesture state.
    observer.next(currentValue(for: gesture))
  }

  @objc func didPan(_ gesture: UIPanGestureRecognizer) {
    observer.next(currentValue(for: gesture))
  }

  func currentValue(for gesture: UIPanGestureRecognizer) -> Value {
    return (gesture.state, gesture.location(in: gesture.view!))
  }

  func unsubscribe() {
    gesture?.removeTarget(self, action: #selector(didPan))
    gesture = nil
  }

  var gesture: (UIPanGestureRecognizer)?
  let observer: ValueObserver<Value>
}

public class DelegateObservableExampleViewController: UIViewController {

  var initialPosition: CGPoint = .zero
  var subscriptions: [Subscription] = []
  override public func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    let targetView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    targetView.center = .init(x: view.frame.midX, y: view.frame.midY)
    targetView.backgroundColor = .red
    view.addSubview(targetView)

    let pan = UIPanGestureRecognizer()
    view.addGestureRecognizer(pan)

    let dragStream = IndefiniteObservable { observer in
      return DragProducer(subscribedTo: pan, observer: observer).unsubscribe
    }

    // Must hold a reference to the subscription, otherwise the stream will be deallocated when the
    // subscription goes out of scope.
    subscriptions.append(dragStream.subscribe(observer: ValueObserver {
      if $0.state == .began || $0.state == .changed {
        targetView.layer.position = $0.location
      }
    }))

    subscriptions.append(dragStream.subscribe(observer: ValueObserver {
      print($0.state.rawValue)
    }))
  }
}
