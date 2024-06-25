//
//  FixedWindowCounter.swift
//  
//
//  Created by Adolfo Vera Blasco on 15/6/24.
//

import Combine
import Redis
import Vapor

/**
	Fixed Window Counter algorithm presents the workflow described as follows:

	1. Define a time window has a counter where the store the number of requets for a given time window.
	3. When a user makes a request, the counter for the current time window is incremented by 1.
	4. If the counter is greater than the rate limit, the request is rejected and whe send an HTTP 429 code status.
	5. If the counter is less than the rate limit, the request is accepted.
*/
public final class FixedWindowCounter {
	// Configuration for this rate-limit algorithm
	private let configuration: FixedWindowCounterConfiguration
	// The Redis database where we store the request information
	public let storage: Application.Redis
	// A logger set during Vapor initialization
	public let logging: Logger?
	
	// The Combine Timer publishers
	private var cancellable: AnyCancellable?
	// Keys stored in a given time window
	private var keys = Set<String>()
	
	/**
	 
	 
	*/
	public init(configuration: () -> FixedWindowCounterConfiguration, storage: StorageAction, logging: LoggerAction? = nil) {
		self.configuration = configuration()
		self.storage = storage()
		self.logging = logging?()
		
		self.cancellable = startWindow(havingDuration: self.configuration.timeWindowDuration.inSeconds,
									   performing: resetWindow)
	}
	
	/**
	 
	*/
	deinit {
		cancellable?.cancel()
	}
}

extension FixedWindowCounter: WindowBasedAlgorithm {
	/// 
	public func checkRequest(_ request: Request) async throws {
		guard let requestKey = try? valueFor(field: configuration.appliedField, in: request, inside: configuration.scope) else {
			return
		}
		
		keys.insert(requestKey)
		
		let redisKey = RedisKey(requestKey)
		let timestamp = Date().timeIntervalSince1970
		
		let requestCount = try await storage.rpush([ timestamp ], into: redisKey).get()
		
		if requestCount > configuration.requestPerWindow {
			throw Abort(.tooManyRequests)
		}
	}
	
	public func resetWindow() {
		keys.forEach { key in
			let redisKey = RedisKey(key)
	
			Task {
				do {
					try	await storage.delete(redisKey).get()
				} catch let redisError {
					logging?.error("🚨 Error deleting key \(key): \(redisError.localizedDescription)")
				}
			}
		}
		
		keys.removeAll()
	}
}
