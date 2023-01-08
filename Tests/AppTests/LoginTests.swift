//
//  LoginTests.swift
//  
//
//  Created by Karun Pant on 05/01/23.
//

@testable import XCTVapor
@testable import App

extension XCTApplicationTester {
    
    public func login(_ user: User,
                      plainTextPass: String = "password") throws -> Token.Public {
        var request  = XCTHTTPRequest(method: .POST,
                                      url: "/api/v1/user/login",
                                      headers: [:],
                                      body: ByteBufferAllocator().buffer(capacity: 0))
        request.headers.basicAuthorization = .init(username: user.uName, password: plainTextPass)
        let res = try performTest(request: request)
        return try res.content.decode(Token.Public.self)
    }
    
    @discardableResult
    public func test(_ method: HTTPMethod,
                     _ path: String,
                     headers: HTTPHeaders = [:],
                     body: ByteBuffer? = nil,
                     loggedInRequest: Bool = false,
                     loggedInUser: User? = nil,
                     file: StaticString = #file,
                     line: UInt = #line,
                     beforeReq: (inout XCTHTTPRequest) throws -> () = { _ in },
                     afterRes: (XCTHTTPResponse) throws -> () = { _ in }) throws -> XCTApplicationTester {
        var request = XCTHTTPRequest(method: method,
                                     url: .init(path: path),
                                     headers: headers,
                                     body: body ?? ByteBufferAllocator().buffer(capacity: 0))
        if loggedInRequest || loggedInUser != nil {
            let userToLogin: User
            if let user = loggedInUser {
                userToLogin = user
            } else {
                userToLogin = User(name: "Admin User",
                                   uName: "admin",
                                   password: "password")
            }
            let token = try login(userToLogin)
            request.headers.bearerAuthorization = .init(token: token.value)
        }
        try beforeReq(&request)
        do {
            let response = try performTest(request: request)
            try afterRes(response)
        } catch {
            XCTFail("\(error)", file: file, line: line)
            throw error
        }
        return self
    }
}
