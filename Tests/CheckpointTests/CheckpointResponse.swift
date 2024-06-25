//
//  CheckpointResponse.swift
//  
//
//  Created by Adolfo Vera Blasco on 24/6/24.
//

import Redis
import XCTest
import XCTVapor
@testable import Checkpoint

final class CheckpointResponse: XCTestCase {
	func testLeakingBucketResponse() {
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
		
		checkpoint.didFailWithTooManyRequest = { (request, response, metadata) in
			metadata.headers = [
				"X-RateLimit" : "Failure for request \(request.id)"
			]
		}
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#5")
		
		(0...20).forEach { index in
			try? app.test(.GET, "leaking-bucket", headers: apiKeyHeader, afterResponse: { testResponse in
				if index < 10 {
					XCTAssertFalse(testResponse.headers.contains(name: "X-RateLimit"))
				} else {
					XCTAssertTrue(testResponse.headers.contains(name: "X-RateLimit"))
				}
			})
		}
	}
	
	func testTokenBucketResponse() throws {
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
		
		checkpoint.didFailWithTooManyRequest = { (request, response, metadata) in
			metadata.headers = [
				"X-RateLimit" : "Failure for request \(request.id)"
			]
		}
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#6")
		
		(0...20).forEach { index in
			try? app.test(.GET, "token-bucket", headers: apiKeyHeader, afterResponse: { testResponse in
				if index < 10 {
					XCTAssertFalse(testResponse.headers.contains(name: "X-RateLimit"))
				} else {
					XCTAssertTrue(testResponse.headers.contains(name: "X-RateLimit"))
				}
			})
		}
	}
	
	func testFixedWindowCounterResponse() {
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
		
		checkpoint.didFailWithTooManyRequest = { (request, response, metadata) in
			metadata.headers = [
				"X-RateLimit" : "Failure for request \(request.id)"
			]
		}
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#7")
		
		(0...20).forEach { index in
			try? app.test(.GET, "fixed-window-counter", headers: apiKeyHeader, afterResponse: { testResponse in
				if index < 10 {
					XCTAssertFalse(testResponse.headers.contains(name: "X-RateLimit"))
				} else {
					XCTAssertTrue(testResponse.headers.contains(name: "X-RateLimit"))
				}
			})
		}
	}
	
	func testSlidingWindowLogResponse() {
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
		
		checkpoint.didFailWithTooManyRequest = { (request, response, metadata) in
			metadata.headers = [
				"X-RateLimit" : "Failure for request \(request.id)"
			]
		}
		
		app.middleware.use(checkpoint)
		
		var apiKeyHeader = HTTPHeaders()
		apiKeyHeader.add(name: "X-ApiKey", value: "fitomad#8")
		
		(0...20).forEach { index in
			try? app.test(.GET, "sliding-window-log", headers: apiKeyHeader, afterResponse: { testResponse in
				if index < 10 {
					XCTAssertFalse(testResponse.headers.contains(name: "X-RateLimit"))
				} else {
					XCTAssertTrue(testResponse.headers.contains(name: "X-RateLimit"))
				}
			})
		}
	}
}
