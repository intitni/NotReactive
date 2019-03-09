import XCTest
import NotReactive

class NotificationObservationTests: XCTestCase {
    func test() {
        let name = Notification.Name(rawValue: "hello")
        func post(_ value: Int) {
            NotificationCenter.default.post(name: name, object: nil, userInfo: ["value": value])
        }
        var received = [Int]()
        post(1)
        let d = NotificationCenter.default.observe(name).subscribe { noti in
            guard let userInfo = noti.userInfo,
                let value = userInfo["value"] as? Int
                else { XCTAssert(false); return }
            received.append(value)
        }
        post(2)
        post(3)
        d.dispose()
        post(4)
        XCTAssertEqual(received, [2,3])
    }
}
