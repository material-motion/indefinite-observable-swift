# IndefiniteObservable.swift

[![Build Status](https://travis-ci.org/material-motion/indefinite-observable-swift.svg?branch=develop)](https://travis-ci.org/material-motion/indefinite-observable-swift)
[![codecov](https://codecov.io/gh/material-motion/indefinite-observable-swift/branch/develop/graph/badge.svg)](https://codecov.io/gh/material-motion/indefinite-observable-swift)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/IndefiniteObservable.svg)](https://cocoapods.org/pods/IndefiniteObservable)
[![Platform](https://img.shields.io/cocoapods/p/IndefiniteObservable.svg)](http://cocoadocs.org/docsets/IndefiniteObservable)
[![Docs](https://img.shields.io/cocoapods/metrics/doc-percent/IndefiniteObservable.svg)](http://cocoadocs.org/docsets/IndefiniteObservable)

`IndefiniteObservable` is a minimal implementation of [Observable](http://reactivex.io/rxjs/manual/overview.html)
with no concept of completion or failure.

## Supported languages

- Swift 3

This library does not support Objective-C due to its heavy use of generics.

## Installation

### Installation with CocoaPods

> CocoaPods is a dependency manager for Objective-C and Swift libraries. CocoaPods automates the
> process of using third-party libraries in your projects. See
> [the Getting Started guide](https://guides.cocoapods.org/using/getting-started.html) for more
> information. You can install it with the following command:
>
>     gem install cocoapods

Add `IndefiniteObservable` to your `Podfile`:

    pod 'IndefiniteObservable'

Then run the following command:

    pod install
    
### Installation with Swift Package Manager

Create a `Package.swift` file.

```swift
import PackageDescription

let package = Package(
name: "YourProject",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/material-motion/indefinite-observable-swift.git”, majorVersion: 4)
    ]
)
```

`swift build`
    
### Usage

Import the framework:

    @import IndefiniteObservable;

You will now have access to all of the APIs.

## Example apps/unit tests

Check out a local copy of the repo to access the Catalog application by running the following
commands:

    git clone https://github.com/material-motion/indefinite-observable-swift.git
    cd observable-swift
    pod install
    open IndefiniteObservable.xcworkspace

# Guides

1. [How to make an observable](#how-to-make-an-observable)
1. [How to create a synchronous stream](#how-to-create-a-synchronous-stream)
1. [How to create an asynchronous stream using blocks](#how-to-create-an-asynchronous-stream-using-blocks)
1. [How to subscribe to a stream](#how-to-subscribe-to-a-stream)
1. [How to unsubscribe from a stream](#how-to-unsubscribe-from-a-stream)
1. [How to create an synchronous stream using objects](#how-to-create-an-synchronous-stream-using-objects)

## How to make an observable

In this example we'll make the simplest possible observable type: a value observable. We will use
this concrete type in all of the following guides.

```swift
final class ValueObserver<T>: Observer {
  typealias Value = T

  init(_ next: @escaping (T) -> Void) {
    self.next = next
  }

  let next: (T) -> Void
}

final class ValueObservable<T>: IndefiniteObservable<ValueObserver<T>> {
  func subscribe(_ next: @escaping (T) -> Void) -> Subscription {
    return super.subscribe(observer: ValueObserver(next))
  }
}
```

## How to create a synchronous stream

```swift
let observable = ValueObservable<<#ValueType#>> { observer in
  observer.next(<#value#>)
  return noopDisconnect
}
```

## How to create an asynchronous stream using blocks

If you have an API that provides a block-based mechanism for registering observers then you can
create an asynchronous stream in place like so:

```swift
let observable = ValueObservable<<#ValueType#>> { observer in
  let someToken = registerSomeCallback { callbackValue in
    observer.next(callbackValue)
  }

  return {
    unregisterCallback(someToken)
  }
}
```

## How to subscribe to a stream

```swift
observable.subscribe { value in
  print(value)
}
```

## How to unsubscribe from a stream

Unsubscribing will invoke the observable's disconnect method. To unsubscribe, you must retain a
reference to the subscription instance returned by subscribe.

```swift
let subscription = observable.subscribe { value in
  print(value)
}

subscription.unsubscribe()
```

## How to create an synchronous stream using objects

Many iOS/macOS APIs use delegation for event handling. To connect delegates with a stream you will
need to create a `Producer` class. A `Producer` listens for events with an event delegate like
`didTap` and forwards those events to an IndefiniteObservable's observer.

### Final result

```swift
class DragConnection {
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

  func disconnect() {
    gesture?.removeTarget(self, action: #selector(didPan))
    gesture = nil
  }

  var gesture: (UIPanGestureRecognizer)?
  let observer: ValueObserver<Value>
}

let pan = UIPanGestureRecognizer()
view.addGestureRecognizer(pan)

let dragStream = ValueObservable<DragConnection.Value> { observer in
  return DragConnection(subscribedTo: pan, observer: observer).disconnect
}
let subscription = dragStream.subscribe {
  dump($0.state)
  dump($0.location)
}
```

### Step 1: Define the Producer type

A Producer should be a type of Subscription.

```swift
class <#Name#>Producer: Subscription {
}
```

### Step 2: Define the Value type

```swift
class DragConnection: Subscription {
  typealias Value = (state: UIGestureRecognizerState, location: CGPoint)
}
```

### Step 3: Implement the initializer

Your initializer must accept and store an `ValueObserver<Value>` instance.

```swift
  init(subscribedTo gesture: UIPanGestureRecognizer, observer: ValueObserver<Value>) {
    self.gesture = gesture
    self.observer = observer
  }

  var gesture: (UIPanGestureRecognizer)?
  let observer: ValueObserver<Value>
```

### Step 4: Connect to the event source and send values to the observer

```swift
  init(subscribedTo gesture: UIPanGestureRecognizer, observer: ValueObserver<Value>) {
    ...

    gesture.addTarget(self, action: #selector(didPan))
  }

  @objc func didPan(_ gesture: UIPanGestureRecognizer) {
    observer.next(currentValue(for: gesture))
  }

  func currentValue(for gesture: UIPanGestureRecognizer) -> Value {
    return (gesture.state, gesture.location(in: gesture.view!))
  }
```

### Step 5: Implement disconnect

You are responsible for disconnecting from and releasing any resources here.

```swift
  func disconnect() {
    gesture?.removeTarget(self, action: #selector(didPan))
    gesture = nil
  }
```

### Step 6: (Optional) Provide the initial state

It often is helpful to provide the observer with the current state on registration.

```swift
  init(subscribedTo gesture: UIPanGestureRecognizer, observer: ValueObserver<Value>) {
    ...

    // Populate the observer with the current gesture state.
    observer.next(currentValue(for: gesture))
  }
```

### Step 7: Observe the producer

```swift
let dragStream = ValueObservable<DragConnection.Value> { observer in
  return DragConnection(subscribedTo: pan, observer: observer).disconnect
}
let subscription = dragStream.subscribe {
  dump($0)
}
```

## Contributing

This library is meant to be a minimal implementation that never grows. As such, we only encourage
contributions in the form of documentation, tests, and examples.

Learn more about [our team](https://material-motion.github.io/material-motion/team/),
[our community](https://material-motion.github.io/material-motion/team/community/), and
our [contributor essentials](https://material-motion.github.io/material-motion/team/essentials/).

## License

Licensed under the Apache 2.0 license. See LICENSE for details.
