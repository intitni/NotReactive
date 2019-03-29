public class Observable<V> {
    public class WeakObservation {
        weak var observation: Observable<V>?
        public var latestEvent: Event? { return observation?.latestEvent }
        public func action(_ event: Event) {
            observation?.action(event)
        }
        public func handleDisposable(_ disposable: Disposable) {
            guard let o = observation else { return }
            disposable.disposed(by: o.disposeBag)
        }
        public init(_ s: Observable<V>) { observation = s }
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
    
    var observers = [(String, (Event)->Void)]()
    private(set) var latestEvent: Event? = nil
    let disposeBag = DisposeBag()
    
    deinit { disposeBag.dispose() }
    
    public init(observeBlock: @escaping (WeakObservation)->Disposable) {
        observeBlock(WeakObservation(self)).disposed(by: disposeBag)
    }
    
    func action(_ event: Event) {
        observers.forEach { $0.1(event) }
        latestEvent = event
    }
}

public extension Observable {
    func subscribeEvent(perform block: @escaping (Event)->Void) -> Disposable {
        let uuid = UUID().uuidString
        observers.append((uuid, block))
        if let e = latestEvent { block(e) }
        return Disposable { [uuid] in self.observers.removeAll(where: { $0.0 == uuid }) }
    }
    
    func subscribe(onNext: @escaping (V)->Void) -> Disposable {
        return subscribeEvent { event in
            if case let .next(v) = event { onNext(v) }
        }
    }
    
    func bind<Target: AnyObject>(to target: Target?, at targetKeyPath: WritableKeyPath<Target, V>) -> Disposable {
        return subscribe { [weak target] in target?[keyPath: targetKeyPath] = $0 }
    }
    
    func bind<Target: AnyObject>(to target: Target?, at targetKeyPath: WritableKeyPath<Target, V?>) -> Disposable {
        return subscribe { [weak target] in target?[keyPath: targetKeyPath] = $0 }
    }
}

/// An Observation that ends after action. You may use it for async calls.
public class OneTimeObservation<V>: Observable<V> {
    private var isEnded = false
    override func action(_ event: Observable<V>.Event) {
        guard !isEnded else { return }
        isEnded = true
        super.action(event)
        disposeBag.dispose()
        observers.removeAll()
    }
}
