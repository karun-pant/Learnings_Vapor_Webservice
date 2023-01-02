//
//  UserTests.swift
//
//
//  Created by Karun Pant on 01/01/23.
//

import XCTVapor
@testable import App

final class CategoryTests: XCTestCase {
    
    var app: Application!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = try Application.configureForTest()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.shutdown()
    }
    
    func testCategoryRetrieval() throws {
        try App.Category.saveAllSamples(on: app.db)
        try app.test(.GET,
                     App.Category.apiBase) { res in
            let allSamples = App.Category.SampleCategory.allCases
            let expectationIndex = 0
            try expectationResponse(res,
                                    expectedSample: allSamples[expectationIndex],
                                    expectedIndex: expectationIndex,
                                    countExpectation: allSamples.count)
        }
    }
    
    func testCreateCategory() throws {
        let slang = App.Category.SampleCategory.slang
        let category = App.Category(name: slang.rawValue)
        try app.test(
            .POST,
            App.Category.apiBase,
            beforeRequest: { req in
                try req.content.encode(category)
            },
            afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                let category = try res.content.decode(App.Category.self)
                expectationCategory(category,
                                    expectedSample: slang)
            })
    }
    
    func testGettingSingleCategory() throws {
        let slang = App.Category.SampleCategory.slang
        let category = try App.Category.createAndSave(slang, on: app.db)
        let categoryID = try XCTUnwrap(category.id)
        try app.test(.GET, "\(App.Category.apiBase)/by/\(categoryID)") { res in
            XCTAssertEqual(res.status, .ok)
            let category = try res.content.decode(App.Category.self)
            expectationCategory(category,
                                expectedSample: slang)
        }
        
    }
}

private extension CategoryTests {
    func expectationResponse(_ res: XCTHTTPResponse,
                             expectedSample sample: App.Category.SampleCategory,
                             expectedIndex: Int = 0,
                             countExpectation: Int,
                             file: StaticString = #file,
                             line: UInt = #line) throws {
        XCTAssertEqual(res.status, .ok, file: file, line: line)
        let categories = try res.content.decode([App.Category].self)
        XCTAssertEqual(categories.count, countExpectation,
                       file: file, line: line)
        expectationCategory(categories[expectedIndex],
                            expectedSample: sample,
                            file: file, line: line)
    }
    
    func expectationCategory(_ category: App.Category,
                             expectedSample sample: App.Category.SampleCategory,
                             file: StaticString = #file,
                             line: UInt = #line) {
        XCTAssertEqual(category.name, sample.rawValue,
                       file: file, line: line)
    }
}
