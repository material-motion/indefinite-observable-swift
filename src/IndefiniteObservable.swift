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

/**
 An IndefiniteObservable represents a sequence of values that may be observed.

 IndefiniteObservable is meant for use with streams of values that have no concept of completion.

 This is an implementation of a subset of the Observable interface defined at http://reactivex.io/

 Simple synchronous stream:

     let observable = IndefiniteObservable<Int> { observer in
       observer.next(5)
       return noopDisconnect
     }

     let subscription = observable.subscribe { value in
       print(value)
     }

     subscription.unsubscribe()

 Example of an asynchronous stream:

     let observable = IndefiniteObservable<Int> { observer in
       let someToken = registerSomeCallback { callbackValue in
         observer.next(callbackValue)
       }

       return {
         unregisterCallback(someToken)
       }
     }
 */
open class IndefiniteObservable<O: Observer> {
  public typealias Connect<O> = (O) -> Disconnect

  /** Connect is only invoked when subscribe is invoked. */
  public init(_ connect: @escaping Connect<O>) {
    self.connect = connect
  }

  /**
   Subscribes to the IndefiniteObservable.

   The returned subscription will hold a strong reference to the IndefiniteObservable chain. The
   reference can be released by calling unsubscribe on the returned subscription. The Subscription
   is type-erased, making it possible to keep a collection of Subscription objects for as long as
   you need the associated streams alive.

   - Parameter next: A block that will be executed when new values are sent from upstream.
   - Returns: A subscription.
   */
  public final func subscribe(observer: O) -> Subscription {
    return Subscription(connect(observer))
  }

  private let connect: Connect<O>
}

/** An Observer is provided to an Observable's subscribe method. */
public protocol Observer {
  associatedtype Value
  var next: (Value) -> Void { get }
}

public typealias Disconnect = () -> Void

/** A Subscription is returned by IndefiniteObservable.subscribe. */
public final class Subscription {
  deinit {
    unsubscribe()
  }

  init(_ disconnect: @escaping () -> Void) {
    self.disconnect = disconnect
  }

  public func unsubscribe() {
    disconnect?()
    disconnect = nil
  }

  private var disconnect: (Disconnect)?
}

/**
 A no-op disconnect block that can be returned by connectors when there is no need for teardown.

 Example:

     let observable = IndefiniteObservable<Int> { observer in
       observer.next(5)

       return noopDisconnect
     }
 */
public let noopDisconnect: Disconnect = { }
