public extension NotificationCenter {
    func observe(_ name: Notification.Name) -> Observable<Notification> {
        return Observable { observation in
            return self.subscribe(name) { noti in
                observation.action(.next(noti))
            }
        }
    }
    
    func subscribe(_ name: Notification.Name, onChange block: @escaping (Notification)->Void) -> Disposable {
        let disposable = addObserver(forName: name, object: nil, queue: nil, using: block)
        return Disposable { [weak self] in
            self?.removeObserver(disposable, name: nil, object: nil)
        }
    }
}
