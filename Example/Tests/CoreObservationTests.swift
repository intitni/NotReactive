import XCTest
@testable import NotReactive

class CoreObservationTests: XCTestCase {
    func testObservableObserve() {
        var received = [Int]()
        let value = Observable<Int>(0)
        value.val = 1
        let disposable = value.observe().subscribe { received.append($0) }
        value.val = 2
        value.val = 3
        value.val = 4
        disposable.dispose()
        value.val = 5
        value.val = 6
        XCTAssertEqual(received, [1,2,3,4])
    }
    
    func testEmitterObserve() {
        var receivedValues = [Int]()
        var receivedEvents = [Observation<Int>.Event]()
        let emitter = Emitter<Int>()
        emitter.emit(0)
        let observation = emitter.observe()
        let d1 = observation.subscribeEvent { receivedEvents.append($0) }
        let d2 = observation.subscribe { receivedValues.append($0) }
        emitter.emit(1)
        emitter.emit(2)
        emitter.emit(NSError())
        d1.dispose()
        emitter.emit(3)
        emitter.emit(NSError())
        d2.dispose()
        emitter.emit(4)
        
        XCTAssertEqual(receivedValues, [0,1,2,3])
        XCTAssertEqual(receivedEvents.count, 4)
        if case let .next(v) = receivedEvents[0], v == 0 { XCTAssert(true) }
        else { XCTAssert(false) }
        if case let .next(v) = receivedEvents[1], v == 1 { XCTAssert(true) }
        else { XCTAssert(false) }
        if case let .next(v) = receivedEvents[2], v == 2 { XCTAssert(true) }
        else { XCTAssert(false) }
        if case .failure = receivedEvents[3] { XCTAssert(true) }
        else { XCTAssert(false) }
    }
    
    func testSingleObservation() {
        let observation = OneTimeObservation<Int> { observation in return Disposable {} }
        var fireCount = 0
        let d = observation.subscribe { _ in fireCount += 1 }
        observation.action(.next(1))
        observation.action(.next(2))
        XCTAssertEqual(fireCount, 1)
        d.dispose()
    }
    
    func testBind() {
        class P {
            var m: Int = 0
            var o: Int? = 0
        }
        
        let value = Observable<Int>(0)
        value.val = 1
        let observation = value.observe()
        let p = P()
        let d1 = observation.bind(to: p, at: \P.m)
        let d2 = observation.bind(to: p, at: \P.o)
        
        XCTAssertEqual(p.m, 1)
        XCTAssertEqual(p.o, 1)
        value.val = 2
        XCTAssertEqual(p.m, 2)
        XCTAssertEqual(p.o, 2)
        d1.dispose()
        value.val = 3
        XCTAssertEqual(p.m, 2)
        XCTAssertEqual(p.o, 3)
        d2.dispose()
        value.val = 4
        XCTAssertEqual(p.m, 2)
        XCTAssertEqual(p.o, 3)
    }
}
