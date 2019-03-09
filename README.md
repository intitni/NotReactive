# NotReactive

[![CI Status](https://img.shields.io/travis/intitni/LightWeightReactive.svg?style=flat)](https://travis-ci.org/intitni/LightWeightReactive)
[![Version](https://img.shields.io/cocoapods/v/LightWeightReactive.svg?style=flat)](https://cocoapods.org/pods/LightWeightReactive)
[![License](https://img.shields.io/cocoapods/l/LightWeightReactive.svg?style=flat)](https://cocoapods.org/pods/LightWeightReactive)
[![Platform](https://img.shields.io/cocoapods/p/LightWeightReactive.svg?style=flat)](https://cocoapods.org/pods/LightWeightReactive)

All those reactive libraries are cool, but they can be too complicated to do right.

## Usage

### Observable<V>

```swift
let value = Observable<Int>(0)
let disposable = value.observe().subscribe { print($0) }
value.val = 1
// prints: 
// 0
// 1
```

### Emitter<V>

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
let value = Observation<Int>(0)
let disposable = value.observe()
    .ignoreLatest()
    .map { $0 }
    .flatMap { $0 }
    .distinct()
    .throttle(seconds: 0.5)
    .on(DispatchQueue.main)
    .filterNil()
    .filter { $0 > 0 }
    .subscribe { print($0) }
    
any(a.observe(), b.observe(), c.observe())
    .subscribe { print($0) }
```

## Installation

LightWeightReactive is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NotReactive'
```

## License

LightWeightReactive is available under the MIT license. See the LICENSE file for more info.
