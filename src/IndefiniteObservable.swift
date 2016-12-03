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
       return noUnsubscription
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
open class IndefiniteObservable<T> {
  public typealias Subscriber<T> = (AnyObserver<T>) -> (() -> Void)?

  /** A subscriber is only invoked when subscribe is invoked. */
  public init(_ subscriber: @escaping Subscriber<T>) {
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
  public func subscribe(next: @escaping (T) -> Void) -> Subscription {
    let observer = AnyObserver<T>(next)

    // This line creates our "downstream" data flow.
    let subscription = subscriber(AnyObserver { observer.next($0) })

    // We store a strong reference to self in the subscription in order to keep the stream alive.
    // When the subscription goes away, so does the stream.
    return UpstreamSubscription(observable: self) {
      subscription?()
    }
  }

  private let subscriber: Subscriber<T>
}

/** An Observer receives data from an IndefiniteObservable. */
public protocol Observer {
  associatedtype Value
  func next(_ value: Value) -> Void
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

       return noUnsubscription
     }
 */
public let noUnsubscription: (() -> Void)? = nil

// MARK: Type erasing

/** A type-erased observer. */
public final class AnyObserver<T>: Observer {
  public typealias Value = T

  init(_ next: @escaping (Value) -> Void) {
    _next = next
  }

  public func next(_ value: Value) {
    _next(value)
  }

  private let _next: (Value) -> Void
}

// MARK: Private

// Internal class for ensuring that an active subscription keeps its stream alive.
// Streams don't hold strong references down the chain, so our subscriptions hold strong references
// "up" the chain to the IndefiniteObservable type.
private final class UpstreamSubscription: Subscription {
  init(observable: Any, _ unsubscribe: @escaping () -> Void) {
    _observable = observable
    _unsubscribe = unsubscribe
  }

  func unsubscribe() {
    _unsubscribe?()
    _unsubscribe = nil
    _observable = nil
  }

  private var _unsubscribe: (() -> Void)?
  private var _observable: Any?
}
