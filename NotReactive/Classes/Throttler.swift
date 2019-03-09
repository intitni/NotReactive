import Foundation

class Throttler: NSObject {
    private let queue: DispatchQueue
    
    private var job: DispatchWorkItem = .init(block: {})
    private var previousRun: Date = .distantPast
    private var maxInterval: TimeInterval
    
    init(seconds: TimeInterval, queue: DispatchQueue = .main) {
        self.queue = queue
        self.maxInterval = seconds
    }

    func throttle(block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem(){ [weak self] in
            self?.previousRun = Date()
            block()
        }
        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> TimeInterval {
        return Date().timeIntervalSince(referenceDate).rounded()
    }
}
