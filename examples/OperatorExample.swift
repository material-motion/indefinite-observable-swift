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

// This example demonstrates how to create custom operators that can be chained to an
// IndefiniteObservable.

extension IndefiniteObservable {

  // Map from one value type to another.
  public func map<U>(_ transform: @escaping (T) -> U) -> IndefiniteObservable<U> {
    return IndefiniteObservable<U> { observer in
      return self.subscribe {
        observer.next(transform($0))
      }.unsubscribe
    }
  }

  // Only emit values downstream for which passesTest returns true
  public func filter(_ passesTest: @escaping (T) -> Bool) -> IndefiniteObservable<T> {
    return IndefiniteObservable<T> { observer in
      return self.subscribe {
        if passesTest($0) {
          observer.next($0)
        }
      }.unsubscribe
    }
  }
}

public class OperatorExampleViewController: UIViewController {

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

    let dragStream = IndefiniteObservable<DragProducer.Value> { observer in
      return DragProducer(subscribedTo: pan, observer: observer).unsubscribe
    }

    // Note that we avoid keep a strong reference to self in the stream's operators.
    // A strong reference would create a retain cycle:
    //
    // subscription -> stream -> operator -> self -> subscriptions
    //           \------------------------------------/
    //
    let midX = self.view.bounds.midX

    subscriptions.append(dragStream
      .filter { $0.state == .began || $0.state == .changed }
      .map { $0.location }
      .map { .init(x: midX, y: $0.y) }
      .subscribe {
        targetView.layer.position = $0
      }
    )
  }
}
