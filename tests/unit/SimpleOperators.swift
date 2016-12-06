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

import Foundation
import IndefiniteObservable

// Simple operators used by the tests.

public final class ValueObserver<T> {
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
      return self.subscribe(observer: ValueObserver<T> {
        observer.next(transform($0))
      }).unsubscribe
    }
  }

  // Only emit values downstream for which passesTest returns true
  public func filter(_ passesTest: @escaping (T) -> Bool) -> ValueObservable<T> {
    return ValueObservable<T> { observer in
      return self.subscribe(observer: ValueObserver<T> {
        if passesTest($0) {
          observer.next($0)
        }
      }).unsubscribe
    }
  }
}
