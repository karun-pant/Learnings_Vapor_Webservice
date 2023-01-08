//
//  AcronymTests.swift
//  
//
//  Created by Karun Pant on 01/01/23.
//

import XCTVapor
@testable import App

final class AcronymTests: XCTestCase {
    
    var app: Application!
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = try Application.configureForTest()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.shutdown()
    }
    
    func testAcronymRetrieval() throws {
        // insert
        let allSamples = Acronym.SampleAcronym.allCases
        try allSamples.forEach { sample in
            _ = try Acronym.createAndSave(sample ,on: app.db)
        }
        
        // test
        try app.test(.GET, "\(Acronym.apiBase)/all",
                     afterResponse: { res in
            try expectationResponse(res,
                                    countExpectation: allSamples.count,
                                    expectatedIndex: 0,
                                    expectedSample: allSamples[0])
            try expectationResponse(res,
                                    countExpectation: allSamples.count,
                                    expectatedIndex: 1,
                                    expectedSample: allSamples[1])
        })
    }
    
    func testCreateAcronym() throws {
        // Make 2 req and test if correctly stores 2 items
        let expectedUser = try User.createAndSave(on: app.db)
        let asap = Acronym.SampleAcronym.asap
        let acronymDTO = AcronymDTO(short: asap.short,
                                    long: asap.long)
        try app.test(.POST, Acronym.apiBase,
                     loggedInUser: expectedUser,
                     beforeReq: { req in
            try req.content.encode(acronymDTO)
        }, afterRes: { res in
            try app.test(.GET, "\(Acronym.apiBase)/base_typed", afterResponse: { res in
                try expectationResponse(res,
                                        countExpectation: 1,
                                        expectedSample: asap)
            })
        })
        
        let lol = Acronym.SampleAcronym.lol
        let acronymDTO1 = AcronymDTO(short: lol.short,
                                     long: lol.long)
        try app.test(.POST, Acronym.apiBase,
                     loggedInUser: expectedUser,
                     beforeReq: { req in
            try req.content.encode(acronymDTO1)
        }, afterRes: { res in
            try app.test(.GET, "\(Acronym.apiBase)/base_typed", afterResponse: { res in
                try expectationResponse(res,
                                        countExpectation: 2,
                                        expectatedIndex: 1,
                                        expectedSample: lol)
            })
        })
    }
    
    func testGettingSingleAcronym() throws {
        let expectedAcronym = try Acronym.createAndSave(.asap, on: app.db)
        let id = try XCTUnwrap(expectedAcronym.id)
        try app.test(.GET, "\(Acronym.apiBase)/by/\(id)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let acronym = try res.content.decode(Acronym.self)
            expectationAcronym(acronym, sample: .asap)
        })
    }
    
    func testAcronymUserRetrieval() throws {
        _ = try Acronym.createAndSave(.asap,
                                      user: User.createAndSave(name: "Test User",
                                                               userName: "TUSer",
                                                               on: app.db),
                                      on: app.db)
        _ = try Acronym.createAndSave(.lol,
                                      user: User.createAndSave(name: "Tester Tea",
                                                               userName: "TTea",
                                                               on: app.db),
                                      on: app.db)
        try app.test(.GET, "\(Acronym.apiBase)/all", afterResponse: { res in
            let acronymResponse = try res.content.decode(AcronymResponse.self)
            XCTAssertEqual(acronymResponse.acronyms.count, 2)
            
            // First Acronym
            try expectationAcronymItem(acronymResponse.acronyms[0],
                                       sample: .asap,
                                       shouldExpectUser: true,
                                       userName: "Test User",
                                       userUName: "TUSer")
            
            // Second Acronym
            try expectationAcronymItem(acronymResponse.acronyms[1],
                                       sample: .lol,
                                       shouldExpectUser: true,
                                       userName: "Tester Tea",
                                       userUName: "TTea")
        })
    }
}

private extension AcronymTests {
    func expectationResponse(_ res: XCTHTTPResponse,
                             countExpectation: Int,
                             expectatedIndex: Int = 0,
                             expectedSample sample: Acronym.SampleAcronym,
                             shouldExpectUser: Bool = false,
                             userName: String? = nil,
                             userUName: String? = nil,
                             file: StaticString = #file,
                             line: UInt = #line) throws {
        if let acronyms = try? res.content.decode([Acronym].self) {
            XCTAssertEqual(acronyms.count, countExpectation,
                           file: file, line: line)
            expectationAcronym(acronyms[expectatedIndex],
                               sample: sample,
                               file: file, line: line)
        } else if let response = try? res.content.decode(AcronymResponse.self) {
            try expectationAcronymResponse(response,
                                           countExpectation: countExpectation,
                                           expectedIndex: expectatedIndex,
                                           expectedSample: sample,
                                           shouldExpectUser: shouldExpectUser,
                                           userName: userName,
                                           userUName: userUName,
                                           file: file, line: line)
        } else {
            XCTFail("Not a valid response", file: file, line: line)
        }
    }
    
    func expectationAcronym(_ acronym: Acronym,
                            sample: Acronym.SampleAcronym,
                            file: StaticString = #file,
                            line: UInt = #line) {
        XCTAssertEqual(acronym.short, sample.short,
                       file: file, line: line)
        XCTAssertEqual(acronym.long, sample.long,
                       file: file, line: line)
    }
    
    func expectationAcronymResponse(_ acronymResponse: AcronymResponse,
                                    countExpectation: Int,
                                    errorExpectation: String? = nil,
                                    expectedIndex: Int = 0,
                                    expectedSample sample: Acronym.SampleAcronym,
                                    shouldExpectUser: Bool = false,
                                    userName: String? = nil,
                                    userUName: String? = nil,
                                    file: StaticString = #file,
                                    line: UInt = #line) throws {
        if acronymResponse.acronyms.isEmpty,
           let error = acronymResponse.errorDescription {
            XCTAssertEqual(error, errorExpectation,
                           file: file, line: line)
        } else if !acronymResponse.acronyms.isEmpty {
            let acronym = acronymResponse.acronyms[expectedIndex]
            try expectationAcronymItem(acronym,
                                       sample: sample,
                                       shouldExpectUser: shouldExpectUser,
                                       userName: userName,
                                       userUName: userUName,
                                       file: file, line: line)
        }
    }
    
    func expectationAcronymItem(_ acronymItem: AcronymItem,
                                sample: Acronym.SampleAcronym,
                                shouldExpectUser: Bool = false,
                                userName: String? = nil,
                                userUName: String? = nil,
                                file: StaticString = #file,
                                line: UInt = #line) throws {
        XCTAssertEqual(acronymItem.short, sample.short,
                       file: file, line: line)
        XCTAssertEqual(acronymItem.long, sample.long,
                       file: file, line: line)
        let displayTextExpectation = "'\(sample.short)' stands for '\(sample.long)'"
        XCTAssertEqual(acronymItem.displayText, displayTextExpectation,
                       file: file, line: line)
        
        if shouldExpectUser {
            XCTAssertNotNil(acronymItem.user,
                            file: file, line: line)
            let user = try XCTUnwrap(acronymItem.user,
                                     "Not able to parse user, user is nil.",
                                     file: file, line: line)
            let expectedName = try XCTUnwrap(userName,
                                             "Expectations not passed clearly userName",
                                             file: file, line: line)
            let expectedUName = try XCTUnwrap(userUName, "Expectations not passed clearly userUName",
                                              file: file, line: line)
            try expectationUser(user,
                                expectedName: expectedName,
                                expectedUName: expectedUName,
                                file: file, line: line)
        }
    }
    
    func expectationUser(_ user: User.Public,
                         expectedName: String,
                         expectedUName: String,
                         file: StaticString = #file,
                         line: UInt = #line) throws {
        XCTAssertEqual(user.name, expectedName,
                       file: file, line: line)
        XCTAssertEqual(user.uName, expectedUName,
                       file: file, line: line)
    }
}
