public class Observation<V> {
    public class WeakObservation {
        weak var observation: Observation<V>?
        public var latestEvent: Event? { return observation?.latestEvent }
        public func action(_ event: Event) {
            observation?.action(event)
        }
        public func handleDisposable(_ disposable: Disposable) {
            guard let o = observation else { return }
            disposable.disposed(by: o.disposeBag)
        }
        public init(_ s: Observation<V>) { observation = s }
    }
    
    public enum Event {
        case next(V)
        case failure(Error)
        var eventType: PossibleEvent {
            switch self {
            case .next: return .next
            case .failure: return .failure
            }
        }
    }
    
    /// Possible events that received by `Observation`.
    public enum PossibleEvent {
        case next
        case failure
    }
    
    private var observers = [(String, (Event)->Void)]()
    private(set) var latestEvent: Event? = nil
    private let disposeBag = DisposeBag()
    
    deinit { disposeBag.dispose() }
    
    public init(observeBlock: @escaping (WeakObservation)->Disposable) {
        observeBlock(WeakObservation(self)).disposed(by: disposeBag)
    }
    
    private func action(_ event: Event) {
        observers.forEach { $0.1(event) }
        latestEvent = event
    }
    
    public func subscribeEvent(perform block: @escaping (Event)->Void) -> Disposable {
        let uuid = UUID().uuidString
        observers.append((uuid, block))
        if let e = latestEvent { block(e) }
        return Disposable { [uuid] in self.observers.removeAll(where: { $0.0 == uuid }) }
    }
    
    public func subscribe(onNext: @escaping (V)->Void) -> Disposable {
        return subscribeEvent { event in
            if case let .next(v) = event { onNext(v) }
        }
    }
    
    public func bind<Target: AnyObject>(to target: Target?, at targetKeyPath: WritableKeyPath<Target, V>) -> Disposable {
        return subscribe { [weak target] in target?[keyPath: targetKeyPath] = $0 }
    }
    
    public func bind<Target: AnyObject>(to target: Target?, at targetKeyPath: WritableKeyPath<Target, V?>) -> Disposable {
        return subscribe { [weak target] in target?[keyPath: targetKeyPath] = $0 }
    }
}

/// Sends events to observers.
public class Notifier<V> {
    typealias ObserverBlock = (Observation<V>.Event) -> Void
    typealias Observer = (String, ObserverBlock)
    
    private var observers = [Observer]()
    public var latestEvent: Observation<V>.Event? = nil
    
    private func addObserver(_ block: @escaping ObserverBlock) -> Disposable {
        let uuid = UUID().uuidString
        observers.append((uuid, block))
        return Disposable { [weak self, uuid] in
            guard let self = self else { return }
            self.observers.removeAll(where: { $0.0 == uuid })
        }
    }
    
    /// Sends events to observers.
    public func notify(_ event: Observation<V>.Event) {
        latestEvent = event
        observers.forEach { $0.1(event) }
    }
    
    /// Creates an observation on a specific queue.
    public func observe() -> Observation<V> {
        let queue = DispatchQueue.main
        return Observation { observation in
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
public class Observable<V>: Notifier<V> {
    public var oldValue: V? = nil
    public var val: V {
        didSet {
            self.oldValue = oldValue
            notify(.next(val))
        }
    }
    
    public init(_ val: V) { self.val = val; super.init(); self.latestEvent = .next(val) }
}
