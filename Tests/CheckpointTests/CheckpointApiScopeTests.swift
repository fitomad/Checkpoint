//
//  CheckpointApiScopeTests.swift
//  
//
//  Created by Adolfo Vera Blasco on 24/6/24.
//

import Redis
import XCTest
import XCTVapor
@testable import Checkpoint

final class CheckpointApiScoreTests: XCTestCase {
	func testLeakingBucketWithScopeApiHeader() {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("leaking-bucket") { request -> HTTPStatus in
			return .ok
		}
		
		let leakingBucketAlgorithm = LeakingBucket {
			LeakingBucketConfiguration(bucketSize: 10,
									   removingRate: 5,
									   removingTimeInterval: .minutes(count: 1),
									   appliedTo: .header(key: "X-ApiKey"),
									   inside :.endpoint)
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 9090,
																	 database: 0)
			
			return app.redis("rate")
		}
		
		let checkpoint = Checkpoint(using: leakingBucketAlgorithm)
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#1")
		
		(0...20).forEach { index in
			try? app.test(.GET, "leaking-bucket", headers: apiKeyHeader, afterResponse: { testResponse in
				app.logger.info("leaking-bucket \(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
	
	func testTokenBucketWithScopeApiHeader() throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("token-bucket") { request -> HTTPStatus in
			return .ok
		}
		
		let tokenbucketAlgorithm = TokenBucket {
			TokenBucketConfiguration(bucketSize: 10,
									 refillRate: 0,
									 refillTimeInterval: .seconds(count: 20),
									 appliedTo: .header(key: "X-ApiKey"),
									 inside: .endpoint)
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 9090,
																	 database: 0)
			
			return app.redis("rate")
		} logging: {
			app.logger
		}
		
		let checkpoint = Checkpoint(using: tokenbucketAlgorithm)
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#2")
		
		(0...20).forEach { index in
			try? app.test(.GET, "token-bucket", headers: apiKeyHeader, afterResponse: { testResponse in
				app.logger.info("token-bucket \(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
	
	func testFixedWindowCounterScopeApiWithHeader() {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("fixed-window-counter") { request -> HTTPStatus in
			return .ok
		}
		
		let fixedWindowAlgorithm = FixedWindowCounter {
			FixedWindowCounterConfiguration(requestPerWindow: 10,
											timeWindowDuration: .minutes(count: 2),
											appliedTo: .header(key: "X-ApiKey"),
											inside: .endpoint)
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 9090,
																	 database: 0)
			
			return app.redis("rate")
		}
		
		
		let checkpoint = Checkpoint(using: fixedWindowAlgorithm)
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#3")
		
		(0...20).forEach { index in
			try? app.test(.GET, "fixed-window-counter", headers: apiKeyHeader, afterResponse: { testResponse in
				app.logger.info("fixed-window-counter \(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
	
	func testSlidingWindowLogScopeApiWithHeader() {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("sliding-window-log") { request -> HTTPStatus in
			return .ok
		}
		
		let slidingWindowLogAlgorith = SlidingWindowLog {
			SlidingWindowLogConfiguration(requestPerWindow: 10,
										  windowDuration: .minutes(count: 2),
										  appliedTo: .header(key: "X-ApiKey"),
										  inside: .endpoint)
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 9090,
																	 database: 0)
			
			return app.redis("rate")
		}
		
		
		let checkpoint = Checkpoint(using: slidingWindowLogAlgorith)
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#4")
		
		(0...20).forEach { index in
			try? app.test(.GET, "sliding-window-log", headers: apiKeyHeader, afterResponse: { testResponse in
				app.logger.info("sliding-window-log \(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
}
