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

import XCTest
import CoreGraphics
import IndefiniteObservable

class MemoryLeakTests: XCTestCase {
  func testObservableIsDeallocated() {
    var observable: IndefiniteObservable<CGFloat>? = IndefiniteObservable<CGFloat> { observer in
      observer.next(5)
      return noopUnsubscription
    }
    weak var weakObservable = observable

    autoreleasepool {
      // Remove our only strong reference.
      observable = nil
    }

    // If this fails it means there's a retain cycle. Place a breakpoint here and use the Debug
    // Memory Graph tool to debug.
    XCTAssertNil(weakObservable)
  }

  func testDownstreamObservableKeepsUpstreamAlive() {
    var observable: IndefiniteObservable<CGFloat>? = IndefiniteObservable<CGFloat> { observer in
      observer.next(5)
      return noopUnsubscription
    }
    weak var weakObservable = observable

    let downstream = observable!.map { $0 }

    autoreleasepool {
      observable = nil
    }

    let _ = downstream // Silence warnings.

    // The downstream ref should keep our observable in scope.
    XCTAssertNotNil(weakObservable)
  }

  func testSubscribedObservableIsDeallocated() {
    var observable: IndefiniteObservable<CGFloat>? = IndefiniteObservable<CGFloat> { observer in
      observer.next(5)
      return noopUnsubscription
    }
    weak var weakObservable = observable

    autoreleasepool {
      let _ = observable!.subscribe {
        let _ = $0
      }
      // Remove our only strong reference.
      observable = nil
    }

    // If this fails it means there's a retain cycle. Place a breakpoint here and use the Debug
    // Memory Graph tool to debug.
    XCTAssertNil(weakObservable)
  }

  func testSubscribedObservableWithOperatorIsDeallocated() {
    var observable: IndefiniteObservable<CGFloat>? = IndefiniteObservable<CGFloat> { observer in
      observer.next(5)
      return noopUnsubscription
    }
    weak var weakObservable = observable

    autoreleasepool {
      let _ = observable!.map { value in
        return value * value
        }.subscribe {
          let _ = $0
        }
      // Remove our only strong reference.
      observable = nil
    }

    // If this fails it means there's a retain cycle. Place a breakpoint here and use the Debug
    // Memory Graph tool to debug.
    XCTAssertNil(weakObservable)
  }

  func testUnsubscribedObservableWithOperatorIsDeallocated() {
    weak var weakObservable: IndefiniteObservable<CGFloat>?
    autoreleasepool {
      let observable: IndefiniteObservable<CGFloat>? = IndefiniteObservable<CGFloat> { observer in
        observer.next(5)
        return noopUnsubscription
      }
      weakObservable = observable

      let subscription = observable!.map { value in
        return value * value
        }.subscribe {
          let _ = $0
        }
      // Remove our only strong reference.
      subscription.unsubscribe()
    }

    // If this fails it means there's a retain cycle. Place a breakpoint here and use the Debug
    // Memory Graph tool to debug.
    XCTAssertNil(weakObservable)
  }

  func testSubscriptionDoesNotKeepObservableInMemory() {
    weak var weakObservable: IndefiniteObservable<Int>?
    var subscription: Subscription?

    autoreleasepool {
      let value = 10
      let observable = IndefiniteObservable<Int> { observer in
        observer.next(value)
        return noopUnsubscription
      }
      weakObservable = observable

      subscription = observable.subscribe { _ in }
    }

    XCTAssertNil(weakObservable)

    subscription?.unsubscribe()
  }
}
