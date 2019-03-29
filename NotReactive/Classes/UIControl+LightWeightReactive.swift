#if canImport(UIKit)

import UIKit

class TargetAction: NSObject {
    private let block: ()->Void
    
    init(action: @escaping ()->Void) {
        self.block = action
        super.init()
    }
    
    @objc func performAction() {
        block()
    }
}

public protocol UIControlObservable: AnyObject {}

public extension UIControlObservable where Self: UIControl {
    func observe<V>(_ event: UIControl.Event, take keyPath: KeyPath<Self, V>) -> Observable<V> {
        return Observable { observation in
            observation.action(.next(self[keyPath: keyPath])) // 初始值
            return self.subscribe(event) { [weak self] in
                guard let self = self else { return }
                observation.action(.next(self[keyPath: keyPath]))
            }
        }
    }
    
    func observe(_ event: UIControl.Event) -> Observable<Void> {
        return Observable { observation in
            return self.subscribe(event) { observation.action(.next(())) }
        }
    }
    
    func subscribe(_ event: UIControl.Event, block: @escaping ()->Void) -> Disposable {
        let targetAction = TargetAction(action: block)
        addTarget(targetAction, action: #selector(TargetAction.performAction), for: event)
        return Disposable { _ = targetAction } // targetAction doesn't need to be disposed, but need to be held
    }
}

extension UIControl: UIControlObservable { }

#endif
