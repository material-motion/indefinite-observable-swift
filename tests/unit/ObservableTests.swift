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
@testable import IndefiniteObservable

class ObservableTests: XCTestCase {

  func testSubscription() {
    let value = 10

    let observable = IndefiniteObservable<Int> { observer in
      observer.next(value)
      return noopUnsubscription
    }

    let wasReceived = expectation(description: "Value was received")
    let _ = observable.subscribe {
      if $0 == value {
        wasReceived.fulfill()
      }
    }

    waitForExpectations(timeout: 0)
  }

  func testTwoSubsequentSubscriptions() {
    let value = 10

    let observable = IndefiniteObservable<Int> { observer in
      observer.next(value)
      return noopUnsubscription
    }

    let wasReceived = expectation(description: "Value was received")
    let _ = observable.subscribe {
      if $0 == value {
        wasReceived.fulfill()
      }
    }

    let wasReceived2 = expectation(description: "Value was received")
    let _ = observable.subscribe {
      if $0 == value {
        wasReceived2.fulfill()
      }
    }

    waitForExpectations(timeout: 0)
  }

  func testTwoParalellSubscriptions() {
    let value = 10

    let observable = IndefiniteObservable<Int> { observer in
      observer.next(value)
      return noopUnsubscription
    }

    let wasReceived = expectation(description: "Value was received")
    let subscription1 = observable.subscribe {
      if $0 == value {
        wasReceived.fulfill()
      }
    }

    let wasReceived2 = expectation(description: "Value was received")
    let subscription2 = observable.subscribe {
      if $0 == value {
        wasReceived2.fulfill()
      }
    }

    waitForExpectations(timeout: 0)

    subscription1.unsubscribe()
    subscription2.unsubscribe()
  }

  func testMappingValues() {
    let value = 10
    let observable = IndefiniteObservable<Int> { observer in
      observer.next(value)
      return noopUnsubscription
    }

    let wasReceived = expectation(description: "Value was received")
    let _ = observable.map { $0 * $0 }.subscribe {
      if $0 == value * value {
        wasReceived.fulfill()
      }
    }

    waitForExpectations(timeout: 0)
  }

  func testMappingTypes() {
    let value = CGPoint(x: 0, y: 10)
    let observable = IndefiniteObservable<CGPoint> { observer in
      observer.next(value)
      return noopUnsubscription
    }

    let wasReceived = expectation(description: "Value was received")
    let _ = observable.map { $0.y }.subscribe {
      if $0 == value.y {
        wasReceived.fulfill()
      }
    }

    waitForExpectations(timeout: 0)
  }

  func testFilteringValues() {
    let value = CGPoint(x: 0, y: 10)
    let observable = IndefiniteObservable<(Bool, CGPoint)> { observer in
      observer.next((false, value))
      observer.next((true, value))
      return noopUnsubscription
    }

    var filteredValues: [CGPoint] = []
    let _ = observable.filter { (state, _) in state == true }.map { $0.1 }.subscribe {
      filteredValues.append($0)
    }

    XCTAssertEqual(filteredValues, [value])
  }

  class DeferredGenerator {
    func addObserver(_ observer: ValueObserver<Int>) {
      observers.append(observer)
    }

    func removeObserver(_ observer: ValueObserver<Int>) {
      if let index = observers.index(where: { $0 === observer }) {
        observers.remove(at: index)
      }
    }

    func emit(_ value: Int) {
      for observer in observers {
        observer.next(value)
      }
    }
    var observers: [ValueObserver<Int>] = []
  }

  func testGeneratedValuesAreReceived() {
    let generator = DeferredGenerator()

    let observable = IndefiniteObservable<Int> { observer in
      generator.addObserver(observer)
      return {
        generator.removeObserver(observer)
      }
    }

    var valuesObserved: [Int] = []
    let subscription1 = observable.subscribe {
      valuesObserved.append($0)
    }

    let subscription2 = observable.subscribe {
      valuesObserved.append($0 * 2)
    }

    generator.emit(5)
    generator.emit(10)
    generator.emit(2)

    XCTAssertEqual(valuesObserved, [5, 10, 10, 20, 2, 4])

    subscription1.unsubscribe()
    subscription2.unsubscribe()
  }

  func testGeneratedValuesAreNotReceivedAfterUnsubscription() {
    let generator = DeferredGenerator()

    let observable = IndefiniteObservable<Int> { observer in
      generator.addObserver(observer)
      return {
        generator.removeObserver(observer)
      }
    }

    var valuesObserved: [Int] = []
    let subscription1 = observable.subscribe {
      valuesObserved.append($0)
    }

    let subscription2 = observable.subscribe {
      valuesObserved.append($0 * 2)
    }

    generator.emit(5)
    generator.emit(10)
    subscription2.unsubscribe()
    generator.emit(2)

    XCTAssertEqual(valuesObserved, [5, 10, 10, 20, 2])

    subscription1.unsubscribe()
  }

  func testGeneratedValuesAreNotReceivedAfterUnsubscriptionOrder2() {
    weak var weakObservable: IndefiniteObservable<Int>?
    autoreleasepool {
      let generator = DeferredGenerator()

      let observable = IndefiniteObservable<Int> { observer in
        generator.addObserver(observer)
        return {
          generator.removeObserver(observer)
        }
      }
      weakObservable = observable

      var valuesObserved: [Int] = []
      let subscription1 = observable.subscribe {
        valuesObserved.append($0)
      }

      let subscription2 = observable.map { $0 * 2 }.subscribe {
        valuesObserved.append($0)
      }

      generator.emit(5)
      generator.emit(10)
      subscription1.unsubscribe()
      generator.emit(2)

      XCTAssertEqual(valuesObserved, [5, 10, 10, 20, 4])

      subscription2.unsubscribe()
    }

    // If this fails it means there's a retain cycle. Place a breakpoint here and use the Debug
    // Memory Graph tool to debug.
    XCTAssertNil(weakObservable)
  }
}
