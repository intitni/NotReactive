import Foundation

extension DispatchQueue {
    func safeAsync(execute block: @escaping ()->Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
    
    func safeSync(execute block: @escaping ()->Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            sync { block() }
        }
    }
}
