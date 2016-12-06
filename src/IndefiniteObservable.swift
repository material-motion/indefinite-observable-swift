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
       return noopUnsubscription
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
open class IndefiniteObservable<O> {
  public typealias Subscriber<O> = (O) -> (() -> Void)?

  /** A subscriber is only invoked when subscribe is invoked. */
  public init(_ subscriber: @escaping Subscriber<O>) {
    self.subscriber = subscriber
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
    if let subscription = subscriber(observer) {
      return SimpleSubscription(subscription)
    } else {
      return SimpleSubscription()
    }
  }

  private let subscriber: Subscriber<O>
}

/** A Subscription is returned by IndefiniteObservable.subscribe. */
public protocol Subscription {
  func unsubscribe()
}

/**
 A no-op subscription that can be returned by subscribers when there is no need for teardown.

 Does nothing when unsubscribe is invoked.

 Example:

     let observable = IndefiniteObservable<Int> { observer in
       observer.next(5)

       return noopUnsubscription
     }
 */
public let noopUnsubscription: (() -> Void)? = nil

// MARK: Private

// Internal class for ensuring that an active subscription keeps its stream alive.
// Streams don't hold strong references down the chain, so our subscriptions hold strong references
// "up" the chain to the IndefiniteObservable type.
private final class SimpleSubscription: Subscription {
  deinit {
    unsubscribe()
  }

  init(_ unsubscribe: @escaping () -> Void) {
    _unsubscribe = unsubscribe
  }

  init() {
    _unsubscribe = nil
  }

  func unsubscribe() {
    _unsubscribe?()
    _unsubscribe = nil
  }

  private var _unsubscribe: (() -> Void)?
}
