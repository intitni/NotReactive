//
//  UIControlObservationTests.swift
//  LightWeightReactive_Tests
//
//  Created by Shangxin Guo on 2019/3/8.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import UIKit
import NotReactive

class UIControlObservationTests: XCTestCase {
    func test() {
        let button = UIButton(type: .custom)
        var tapCount = 0
        let d = button.observe(.touchUpInside).subscribe {
            tapCount += 1
        }
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        d.dispose()
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(tapCount, 3)
    }
    
    func testTake() {
        let button = UIButton(type: .custom)
        button.setTitle("Hello", for: .normal)
        var tapCount = 0
        let d = button.observe(.touchUpInside, take: \UIButton.currentTitle).subscribe { title in
            XCTAssertEqual(title, "Hello")
            tapCount += 1
        }
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        d.dispose()
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(tapCount, 4) // when takes, subscribe counts 1
    }
}
