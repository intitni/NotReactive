import XCTest
import NotReactive

class KVOObservationTests: XCTestCase { 
    func testKVOObservation() {
        class KVO: NSObject {
            @objc dynamic var value: Int = 0
        }
        
        var received = [Int]()
        let kvo = KVO()
        kvo.value = 2
        let d = kvo.observe(\.value).subscribe { new in received.append(new) }
        kvo.value = 3
        kvo.value = 4
        d.dispose()
        kvo.value = 5
        
        XCTAssertEqual(received, [2,3,4])
    }
    
    func testKVOObservation2() {
        class KVO: NSObject {
            @objc dynamic var value: NSNumber? = .init(value: 0)
        }
        
        var received = [NSNumber?]()
        let kvo = KVO()
        kvo.value = .init(value: 2)
        let d = kvo.observe(\.value).subscribe { new in received.append(new) }
        let o = kvo.observe(\.value)
        kvo.value = nil
        kvo.value = .init(value: 4)
        d.dispose()
        kvo.value = .init(value: 5)
        
        let result: [NSNumber?] = [NSNumber.init(value: 2), nil, NSNumber.init(value: 4)]
        XCTAssertEqual(received, result)
    }
}
