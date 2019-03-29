/// Sends events to observers.
public class Notifier<V> {
    public typealias ObserverBlock = (Observable<V>.Event) -> Void
    public typealias Observer = (String, ObserverBlock)
    
    public var observers = [Observer]()
    public var latestEvent: Observable<V>.Event? = nil
    
    private func addObserver(_ block: @escaping ObserverBlock) -> Disposable {
        let uuid = UUID().uuidString
        observers.append((uuid, block))
        return Disposable { [weak self, uuid] in
            guard let self = self else { return }
            self.observers.removeAll(where: { $0.0 == uuid })
        }
    }
    
    /// Sends events to observers.
    public func notify(_ event: Observable<V>.Event) {
        latestEvent = event
        observers.forEach { $0.1(event) }
    }
    
    /// Creates an observation on a specific queue.
    public func observe() -> Observable<V> {
        let queue = DispatchQueue.main
        return Observable { observation in
            if let e = self.latestEvent { queue.safeAsync { observation.action(e) } }
            return self.addObserver { event in
                queue.safeAsync { observation.action(event) }
            }
        }
    }
}

/// Emits either a next event or failure event.
public class Emitter<V>: Notifier<V> {
    public override init() { super.init() }
    
    public func emit(_ value: V) {
        notify(.next(value))
    }
    public func emit(_ error: Error) {
        notify(.failure(error))
    }
}

/// Notifies changes of value.
public class Value<V>: Notifier<V> {
    public private(set) var oldValue: V? = nil
    public var val: V {
        didSet {
            self.oldValue = oldValue
            notify(.next(val))
        }
    }
    
    public init(_ val: V) { self.val = val; super.init(); self.latestEvent = .next(val) }
}
