import Foundation

public extension NSObjectProtocol where Self: NSObject {
    public func observe<V>(_ keyPath: KeyPath<Self, V>) -> Observation<V> {
        return Observation { observation in
            return self.subscribe(keyPath) { new, _ in
                observation.action(.next(new))
            }
        }
    }

    public func subscribe<V>(_ keyPath: KeyPath<Self, V>, onChange: @escaping (V, V?)->Void) -> Disposable {
        let observation = observe(keyPath, options: [.initial, .new]) { _, change in
            guard let newValue = change.newValue else { return }
            onChange(newValue, change.oldValue)
        }
        return observation.disposable
    }
}

public extension NSKeyValueObservation {
    public var disposable: Disposable { return .init { self.invalidate() } }
}
