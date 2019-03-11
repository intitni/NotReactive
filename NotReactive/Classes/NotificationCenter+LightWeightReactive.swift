public extension NotificationCenter {
    public func observe(_ name: Notification.Name) -> Observation<Notification> {
        return Observation { observation in
            return self.subscribe(name) { noti in
                observation.action(.next(noti))
            }
        }
    }
    
    public func subscribe(_ name: Notification.Name, onChange block: @escaping (Notification)->Void) -> Disposable {
        let disposable = addObserver(forName: name, object: nil, queue: nil, using: block)
        return Disposable { [weak self] in
            self?.removeObserver(disposable, name: nil, object: nil)
        }
    }
}
