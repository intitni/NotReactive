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
}
