extension Observable {
    public struct CompositionError: Error {
        let errors: [Error]
    }
    
    /// Converts value to another observation.
    public func flatMap<M>(_ transform: @escaping (V)->Observable<M>) -> Observable<M> {
        return Observable<M> { observation in
            return self.subscribeEvent { event in
                switch event {
                case let .next(v):
                    let obs = transform(v)
                    let d = obs.subscribeEvent { nextEvent in
                        observation.action(nextEvent)
                    }
                    observation.handleDisposable(d)
                case let .failure(e): observation.action(.failure(e))
                }
            }
        }
    }
    
    /// Converts value to another value.
    public func map<M>(_ transform: @escaping (V)->M) -> Observable<M> {
        return Observable<M> { observation in
            return self.subscribeEvent { event in
                switch event {
                case let .next(v): observation.action(.next(transform(v)))
                case let .failure(e): observation.action(.failure(e))
                }
            }
        }
    }
    
    public func withOldValue() -> Observable<(V, V?)> {
        var previous: V? = nil
        return map { current in
            defer { previous = current }
            return (current, previous)
        }
    }
    
    /// Notify observers on specific queue.
    public func on(_ queue: DispatchQueue) -> Observable<V> {
        return Observable { observation in
            return self.subscribeEvent { event in
                queue.safeAsync { observation.action(event) }
            }
        }
    }
    
    /// Throttles observations.
    public func throttle(seconds: TimeInterval) -> Observable<V> {
        let throttler = Throttler(seconds: seconds)
        return Observable { observation in
            return self.subscribeEvent { event in
                throttler.throttle {
                    switch event {
                    case let .next(v): observation.action(.next(v))
                    case let .failure(e): observation.action(.failure(e))
                    }
                }
            }
        }
    }
    
    /// Notify observers when value passes validation.
    public func filter(_ validate: @escaping (V)->Bool) -> Observable {
        return Observable { observation in
            return self.subscribeEvent { event in
                if case let .next(v) = event, !validate(v) { return }
                observation.action(event)
            }
        }
    }

    /// Ignores the latest event. Useful when you subscribe but don't want the initial value
    public func ignoreLatest() -> Observable<V> {
        var initial = true
        return filter { v in
            defer { initial = false }
            return !initial
        }
    }
    
    public func or<M>(_ another: Observable<M>) -> Observable<(V?, M?)> {
        return Observable<(V?, M?)> { observation in
            let a = self.subscribeEvent { [weak another] event in
                switch (event, another?.latestEvent) {
                case let (.next(lv), .next(rv)?): observation.action(.next((lv, rv)))
                case let (.next(lv), _): observation.action(.next((lv, nil)))
                case let (.failure(error), _): observation.action(.failure(error))
                }
            }
            let b = another.subscribeEvent { [weak self] event in
                switch (event, self?.latestEvent) {
                case let (.next(rv), .next(lv)?): observation.action(.next((lv, rv)))
                case let (.next(rv), _): observation.action(.next((nil, rv)))
                case let (.failure(error), _): observation.action(.failure(error))
                }
            }
            return Disposable { a.dispose(); b.dispose() }
        }
    }
    
    public func and<M>(_ another: Observable<M>) -> Observable<(V, M)> {
        return Observable<(V, M)> { observation in
            let a = self.subscribeEvent { [weak another] event in
                switch (event, another?.latestEvent) {
                case let (.next(lv), .next(rv)?): observation.action(.next((lv, rv)))
                case let (.failure(a), .failure(b)?): observation.action(.failure(CompositionError(errors: [a, b])))
                default: break
                }
            }
            let b = another.subscribeEvent { [weak self] event in
                switch (event, self?.latestEvent) {
                case let (.next(rv), .next(lv)?): observation.action(.next((lv, rv)))
                case let (.failure(a), .failure(b)?): observation.action(.failure(CompositionError(errors: [a, b])))
                default: break
                }
            }
            return Disposable { a.dispose(); b.dispose() }
        }
    }
}

extension Observable where V: Equatable {
    /// Notify observers only when value is changed.
    public func distinct() -> Observable<V> {
        var previous: V? = nil
        return filter { v in
            defer { previous = v }
            return v != previous
        }
    }
}

/// Notify observers when one of the observations changes.
public func any<A, B>(_ a: Observable<A>, _ b: Observable<B>) -> Observable<(A?, B?)> {
    return a.or(b)
}

public func all<A, B>(_ a: Observable<A>, _ b: Observable<B>) -> Observable<(A, B)> {
    return a.and(b)
}

/// Notify observers when one of the observations changes.
public func any<A, B, C>(_ a: Observable<A>, _ b: Observable<B>, _ c: Observable<C>) -> Observable<(A?, B?, C?)> {
    let aOrB = any(a, b)
    return any(aOrB, c).map { arg in let (eab, ec) = arg
        if let eab = eab { return (eab.0, eab.1, ec) }
        return (nil, nil, ec)
    }
}

public func all<A, B, C>(_ a: Observable<A>, _ b: Observable<B>, _ c: Observable<C>) -> Observable<(A, B, C)> {
    return any(a, b, c)
        .filter { $0.0 != nil && $0.1 != nil && $0.2 != nil }
        .map { ($0.0!, $0.1!, $0.2!) }
}

public protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? {
        return self
    }
}

extension Observable where V: OptionalType {
    /// Notify observers when value is not nil
    public func filterNil() -> Observable<V.Wrapped> {
        return filter { $0.value != nil } .map { $0.value! }
    }
}
