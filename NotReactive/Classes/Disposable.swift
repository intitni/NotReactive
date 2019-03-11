public final class DisposeBag {
    private var disposables: [Disposable] = []
    public init() {}
    public func add(_ d: Disposable) {
        disposables.append(d)
    }
    public func dispose() {
        disposables.forEach { $0.dispose() }
        disposables.removeAll()
    }
    deinit {
        if disposables.count > 0 {
            dispose()
        }
    }
}

public final class Disposable {
    private var disposeBlock: (() -> ())?
    public func dispose() {
        disposeBlock?()
        disposeBlock = nil
    }
    public init(_ dispose: @escaping () -> ()) {
        self.disposeBlock = dispose
    }
    public func disposed(by disposeBag: DisposeBag) {
        disposeBag.add(self)
    }
}
