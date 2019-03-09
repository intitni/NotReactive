import XCTest
import NotReactive

class ReferenceCycleTests: XCTestCase {
    func test() {
        class ViewController {
            var received = [Int]()
            let value = Observable<Int>(0)
            let disposeBag = DisposeBag()
            weak var obs: Observation<Int>?
            weak var ignoreLatestObs: Observation<Int>?
            weak var distinctObs: Observation<Int>?
            var expectation: XCTestExpectation?
            
            deinit {
                disposeBag.dispose()
                expectation?.fulfill()
            }
            
            func unload() {
                disposeBag.dispose()
            }
            
            func load() {
                let o1 = value.observe()
                obs = o1
                let o2 = o1.map { $0 }
                ignoreLatestObs = o2
                let o3 = o2.distinct()
                distinctObs = o3
                o3.subscribe(onNext: { [weak self] v in self?.received.append(v) }).disposed(by: disposeBag)
            }
        }
        
        weak var weakRef: ViewController? = nil
        var vc: ViewController! = ViewController()
        weakRef = vc
        vc.load()
        vc.value.val = 1
        vc.value.val = 2
        XCTAssertNotNil(vc.obs)
        XCTAssertNotNil(vc.ignoreLatestObs)
        XCTAssertNotNil(vc.distinctObs)
        XCTAssertEqual(vc.received, [0,1,2])
        vc.unload()
        vc.value.val = 3
        vc.value.val = 4
        
        // subscription should be disposed by unload
        XCTAssertEqual(vc.received, [0,1,2])
        
        // all intermediate observations should be disposed by unload
        XCTAssertNil(vc.obs)
        XCTAssertNil(vc.ignoreLatestObs)
        XCTAssertNil(vc.distinctObs)
        
        vc.load()
        
        let deinitExpectation = XCTestExpectation(description: "deinit")
        vc.expectation = deinitExpectation
        XCTAssertNotNil(weakRef)
        vc = nil
        
        // ViewController should be able to auto deinit when vc set to nil
        wait(for: [deinitExpectation], timeout: 2)
        XCTAssertNil(weakRef)
    }
}
