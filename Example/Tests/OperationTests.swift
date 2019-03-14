import XCTest
import NotReactive

func isEven(_ v: Int) -> Bool {
    return v % 2 == 0
}

class OperationTests: XCTestCase {
    func testMap() {
        var received = [String]()
        let value = Observable<Int>(0)
        let d = value.observe()
            .map { String($0) }
            .subscribe { received.append($0) }
        value.val = 1
        value.val = 2
        d.dispose()
        value.val = 3
        XCTAssertEqual(received, ["0", "1", "2"])
    }
    
    func testFlatMap() {
        var received = [Int]()
        let value = Observable<Int>(0)
        let o1 = Observable<Int>(1)
        let o2 = Observable<Int>(2)
        let d = value.observe()
            .flatMap { if isEven($0) { return o2.observe() } else { return o1.observe() } }
            .subscribe { received.append($0) }
        value.val = 1
        value.val = 2
        d.dispose()
        value.val = 3
        XCTAssertEqual(received, [1, 2, 1])
    }
    
    func testFilter() {
        var received = [Int]()
        let value = Observable<Int>(0)
        let d = value.observe()
            .filter(isEven)
            .subscribe { received.append($0) }
        value.val = 1
        value.val = 2
        d.dispose()
        value.val = 3
        XCTAssertEqual(received, [0, 2])
    }
    
    func testIgnoreLatest() {
        var received = [Int]()
        let value = Observable<Int>(0)
        let d = value.observe()
            .ignoreLatest()
            .subscribe { received.append($0) }
        value.val = 1
        value.val = 2
        d.dispose()
        value.val = 3
        XCTAssertEqual(received, [1, 2])
    }
    
    func testFilterNil() {
        var received = [Int?]()
        var count = 0
        let value = Observable<Int?>(0)
        let d = value.observe()
            .filterNil()
            .subscribe { count += 1; received.append($0) }
        value.val = 1
        value.val = nil
        value.val = 2
        value.val = nil
        d.dispose()
        value.val = 3
        XCTAssertEqual(received, [0, 1, 2])
        XCTAssertEqual(count, 3)
    }
    
    func testDistinct() {
        var received = [Int]()
        let value = Observable<Int>(0)
        let d = value.observe()
            .distinct()
            .subscribe { received.append($0) }
        value.val = 1
        value.val = 1
        value.val = 2
        value.val = 2
        d.dispose()
        value.val = 3
        XCTAssertEqual(received, [0, 1, 2])
    }
    
    func testOnQueue() {
        let queue = DispatchQueue(label: "hello")
        let value = Observable<Int>(0)
        let d1 = value.observe()
            .on(queue)
            .subscribe { _ in
                XCTAssertFalse(Thread.isMainThread)
            }
        
        value.val = 1
        d1.dispose()
    }
    
    func testAnyAll() {
        var resultAny2 = [(Int?, Int?)]()
        var resultAny3 = [(Int?, Int?, Int?)]()
        var resultAll3 = [(Int, Int, Int)]()
        let a = Observable<Int>(0)
        let b = Observable<Int>(0)
        let c = Emitter<Int>()
        
        let any2 = any(a.observe(), b.observe())
            .subscribe { av, bv in
                resultAny2.append((av, bv))
            }
        
        let any3 = any(a.observe(), b.observe(), c.observe())
            .subscribe { av, bv, cv in
                resultAny3.append((av, bv, cv))
            }
        
        let all3 = all(a.observe(), b.observe(), c.observe())
            .subscribe { av, bv, cv in
                resultAll3.append((av, bv, cv))
            }
        
        a.val = 1
        b.val = 1
        c.emit(1)
        a.val = 2
        c.emit(2)
        any2.dispose()
        a.val = 3
        any3.dispose()
        all3.dispose()
        c.emit(3)
        
        XCTAssert(resultAny2.elementsEqual([(0,0), (1,0), (1,1), (2,1)], by: ==))
        XCTAssert(resultAny3.elementsEqual([(0,0,nil), (1,0,nil), (1,1,nil), (1,1,1), (2,1,1), (2,1,2), (3,1,2)], by: ==))
        XCTAssert(resultAny3.elementsEqual([(1,1,1), (2,1,1), (2,1,2), (3,1,2)], by: ==))
    }
    
    func testThrottling() {
        var received = [Int]()
        let expectation = XCTestExpectation(description: "hi")
        let value = Observable<Int>(0)
        let d = value.observe()
            .throttle(seconds: 1)
            .subscribe { received.append($0); expectation.fulfill() }
        value.val = 1
        XCTAssertEqual(received, [])
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(received, [1])
        d.dispose()
    }
}

func ==(lhs: (Int?,Int?), rhs: (Int?,Int?)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
}

func ==(lhs: (Int?,Int?,Int?), rhs: (Int?,Int?,Int?)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1 && lhs.2 == rhs.2
}


