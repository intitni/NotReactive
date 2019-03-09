//
//  Operations.swift
//  LightWeightReactive
//
//  Created by Shangxin Guo on 2019/3/8.
//

import Foundation

extension Observation {
    /// Converts value to another value.
    public func flatMap<M>(_ transform: @escaping (V)->M?) -> Observation<M> {
        return Observation<M> { observation in
            return self.subscribeEvent { event in
                switch event {
                case let .next(v):
                    guard let next = transform(v) else { return }
                    observation.action(.next(next))
                case let .failure(e): observation.action(.failure(e))
                }
            }
        }
    }
    
    /// Converts value to another value.
    public func map<M>(_ transform: @escaping (V)->M) -> Observation<M> {
        return flatMap { v in return transform(v) }
    }
    
    /// Notify observers on specific queue.
    public func on(_ queue: DispatchQueue) -> Observation<V> {
        return Observation { observation in
            return self.subscribeEvent { event in
                queue.safeAsync { observation.action(event) }
            }
        }
    }
    
    /// Throttles observations.
    public func throttle(seconds: TimeInterval) -> Observation<V> {
        let throttler = Throttler(seconds: seconds)
        return Observation { observation in
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
    
    /// Ignores the latest event. Useful when you subscribe but don't want the initial value
    public func ignoreLatest() -> Observation<V> {
        return Observation { observation in
            var initial = true // 用于判断是否初次事件触发
            return self.subscribeEvent { event in
                guard !initial else { initial = false; return }
                observation.action(event)
            }
        }
    }
    
    /// Notify observers when value passes validation.
    public func filter(_ validate: @escaping (V)->Bool) -> Observation {
        return Observation { observation in
            return self.subscribeEvent { event in
                if case let .next(v) = event, !validate(v) { return }
                observation.action(event)
            }
        }
    }
}

extension Observation where V: Equatable {
    /// Notify observers only when value is changed.
    public func distinct() -> Observation<V> {
        return Observation { observation in
            return self.subscribeEvent { event in
                if case let (.next(v), .next(o)?) = (event, observation.latestEvent), o == v { return }
                observation.action(event)
            }
        }
    }
}

/// Notify observers when one of the observations changes.
public func any<A, B>(_ l: Observation<A>, _ r: Observation<B>) -> Observation<(A?, B?)> {
    return Observation<(A?, B?)> { observation in
        let a = l.subscribeEvent { [weak r] event in
            switch (event, r?.latestEvent) {
            case let (.next(lv), .next(rv)?): observation.action(.next((lv, rv)))
            case let (.next(lv), _): observation.action(.next((lv, nil)))
            case let (.failure(error), _): observation.action(.failure(error))
            }
        }
        let b = r.subscribeEvent { [weak l] event in
            switch (event, l?.latestEvent) {
            case let (.next(rv), .next(lv)?): observation.action(.next((lv, rv)))
            case let (.next(rv), _): observation.action(.next((nil, rv)))
            case let (.failure(error), _): observation.action(.failure(error))
            }
        }
        return Disposable { a.dispose(); b.dispose() }
    }
}

/// Notify observers when one of the observations changes.
public func any<A, B, C>(_ a: Observation<A>, _ b: Observation<B>, _ c: Observation<C>) -> Observation<(A?, B?, C?)> {
    let aOrB = any(a, b)
    return any(aOrB, c).map { arg in let (eab, ec) = arg
        if let eab = eab { return (eab.0, eab.1, ec) }
        return (nil, nil, ec)
    }
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

extension Observation where V: OptionalType {
    /// Notify observers when value is not nil
    public func filterNil() -> Observation<V.Wrapped> {
        return flatMap { v in return v.value }
    }
}
