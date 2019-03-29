# NotReactive

[![Language](https://img.shields.io/badge/language-swift-orange.svg)](https://travis-ci.org/intitni/NotReactive)
[![Version](https://img.shields.io/cocoapods/v/NotReactive.svg?style=flat)](https://cocoapods.org/pods/NotReactive)
[![License](https://img.shields.io/cocoapods/l/NotReactive.svg?style=flat)](https://cocoapods.org/pods/NotReactive)
[![Platform](https://img.shields.io/cocoapods/p/NotReactive.svg?style=flat)](https://cocoapods.org/pods/NotReactive)

All those reactive libraries are cool, but they can be too complicated to do right.

## Usage

### Value<V>

`Value` initializes with a default value. On subscription, observers immediately receive the latest value.

```swift
let value = Value<Int>(0)
let disposable = value.observe().subscribe { print($0) }
value.val = 1
// prints: 
// 0
// 1
```

### Emitter<V>

`Emitter` can send values or errors. Sending errors won't terminate observations. 

```swift
let emitter = Emitter<Int>()
let disposable = emitter.observe().subscribeEvent { print($0) }
emitter.emit(0)
emitter.emit(SomeError)
// prints:
// .next(0)
// .failure(SomeError)
```

### KVO

```swift
let disposable = view.observe(\.frame).subscribe { print($0) }
```

### Notification

```swift
let disposable = NotificationCenter.default.observe(someNotification).subscribe { print($0) }
```

### UIControl

```swift
let button = UIButton()
let disposable = button.observe(.touchUpInside).subscribe { print("tap") }
// prints: 
// tap

let textField = UITextField()
let disposable = textField.observe(.editingChanged, take: \.text).subscribe { print($0) }
// prints:
// textField.text
```

### Operators

```swift
let value = Observable<Int>(0)
let disposable = value.observe()
    .ignoreLatest()
    .map { $0 }
    .flatMap { anotherObservation }
    .distinct()
    .throttle(seconds: 0.5)
    .on(DispatchQueue.main)
    .filterNil()
    .filter { $0 > 0 }
    .subscribe { print($0) } // or bind(to:at:)
    
any(a.observe(), b.observe(), c.observe())
    .subscribe { print($0) }
```

## Installation

NotReactive is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NotReactive'
```

## License

NotReactive is available under the MIT license. See the LICENSE file for more info.
