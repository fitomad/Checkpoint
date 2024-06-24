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
 Algorithm can be described as follows:
 
 1. Timeline is divided into fixed time windows.
 2. Each time window has a counter.
 3. When a request comes in, the counter for the current time window is incremented.
 4. If the counter is greater than the rate limit, the request is rejected.
 5. If the counter is less than the rate limit, the request is accepted.
*/
public final class FixedWindowCounter {
	private let configuration: FixedWindowCounterConfiguration
	public let storage: Application.Redis
	public let logging: Logger?
	
	private var cancellable: AnyCancellable?
	private var keys = Set<String>()
	
	public init(configuration: () -> FixedWindowCounterConfiguration, storage: StorageAction, logging: LoggerAction? = nil) {
		self.configuration = configuration()
		self.storage = storage()
		self.logging = logging?()
		
		self.cancellable = startWindow(havingDuration: self.configuration.timeWindowDuration.inSeconds,
									   performing: resetWindow)
	}
	
	deinit {
		cancellable?.cancel()
	}
}

extension FixedWindowCounter: WindowBasedAlgorithm {
	public func checkRequest(_ request: Request) async throws {
		guard let requestKey = try? valueFor(field: configuration.appliedField, in: request, inside: configuration.scope) else {
			return
		}
		
		keys.insert(requestKey)
		
		let redisKey = RedisKey(requestKey)
		let timestamp = Date.now.timeIntervalSince1970
		
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
