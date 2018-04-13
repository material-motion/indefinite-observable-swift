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

// This example demonstrates how to create a custom observable/observer type and to add operators to
// it.

public final class ValueObserver<T>: Observer {
  public typealias Value = T

  public init(_ next: @escaping (T) -> Void) {
    self.next = next
  }

  public let next: (T) -> Void
}

public class ValueObservable<T>: IndefiniteObservable<ValueObserver<T>> {
  public final func subscribe(_ next: @escaping (T) -> Void) -> Subscription {
    return super.subscribe(observer: ValueObserver(next))
  }
}

extension ValueObservable {

  // Map from one value type to another.
  public func map<U>(_ transform: @escaping (T) -> U) -> ValueObservable<U> {
    return ValueObservable<U> { observer in
      return self.subscribe {
        observer.next(transform($0))
      }.unsubscribe
    }
  }

  // Only emit values downstream for which passesTest returns true
  public func filter(_ passesTest: @escaping (T) -> Bool) -> ValueObservable<T> {
    return ValueObservable<T> { observer in
      return self.subscribe {
        if passesTest($0) {
          observer.next($0)
        }
      }.unsubscribe
    }
  }
}

public enum MotionState {
  case atRest
  case active
}

public final class MotionObserver<T>: Observer {
  public typealias Value = T

  public init(next: @escaping (T) -> Void, state: @escaping (MotionState) -> Void) {
    self.next = next
    self.state = state
  }

  public let next: (T) -> Void
  public let state: (MotionState) -> Void
}

public class MotionObservable<T>: IndefiniteObservable<MotionObserver<T>> {
  public final func subscribe(next: @escaping (T) -> Void, state: @escaping (MotionState) -> Void) -> Subscription {
    return super.subscribe(observer: MotionObserver(next: next, state: state))
  }
}

extension MotionObservable {

  // Map from one value type to another.
  public func map<U>(_ transform: @escaping (T) -> U) -> MotionObservable<U> {
    return MotionObservable<U> { observer in
      return self.subscribe(next: {
        observer.next(transform($0))
      }, state: { state in
        observer.state(state)
      }).unsubscribe
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

    let dragStream = ValueObservable<DragSource.Value> { observer in
      return DragSource(subscribedTo: pan, observer: observer).disconnect
    }

    _ = MotionObservable<Int> { observer in
      observer.next(5)
      observer.state(.atRest)
      return noopDisconnect
    }

    // Note that we avoid keeping a strong reference to self in the stream's operators.
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
      .subscribe(observer: ValueObserver {
        targetView.layer.position = $0
      })
    )
  }
}
