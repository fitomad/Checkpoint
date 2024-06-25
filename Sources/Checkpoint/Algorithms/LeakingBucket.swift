//
//  LeakingBucket.swift
//  
//
//  Created by Adolfo Vera Blasco on 15/6/24.
//

import Combine
import Redis
import Vapor

/**
 Algorithm can be described as follows:
 
 1. Bucket has capacity of b tokens. Let’s say 10 tokens.
 2. When a request comes in, we add 1 token to the bucket.
 3. If the bucket is full, we reject the request and return a 429 status code.
 4. If the bucket is not full, we allow the request and add 1 token from the bucket.
 5. Tokens are removed at a fixed rate of r tokens per second. Let’s say 1 token per second.
*/
public final class LeakingBucket {
	private let configuration: LeakingBucketConfiguration
	public let storage: Application.Redis
	public let logging: Logger?
	
	private var cancellable: AnyCancellable?
	private var keys = Set<String>()
	
	public init(configuration: () -> LeakingBucketConfiguration, storage: StorageAction, logging: LoggerAction? = nil) {
		self.configuration = configuration()
		self.storage = storage()
		self.logging = logging?()
		self.cancellable = startWindow(havingDuration: self.configuration.timeWindowDuration.inSeconds,
									   performing: resetWindow)
	}
	
	deinit {
		cancellable?.cancel()
	}
	
	private func preparaStorageFor(key: RedisKey) async {
		do {
			try await storage.set(key, to: 0).get()
		} catch let redisError {
			logging?.error("🚨 Problem setting key \(key.rawValue) to value \(configuration.bucketSize): \(redisError.localizedDescription)")
		}
	}
}

extension LeakingBucket: WindowBasedAlgorithm {
	public func checkRequest(_ request: Request) async throws {
		guard let requestKey = try? valueFor(field: configuration.appliedField, in: request, inside: configuration.scope) else {
			return
		}
		
		keys.insert(requestKey)
		let redisKey = RedisKey(requestKey)
		
		let keyExists = try await storage.exists(redisKey).get()
		
		if keyExists == 0 {
			await preparaStorageFor(key: redisKey)
		}
		
		// 1. New request, remove one token from the bucket
		let bucketItemsCount = try await storage.increment(redisKey).get()
		// 2. If buckes is empty, throw an error
		if bucketItemsCount > configuration.bucketSize {
			throw Abort(.tooManyRequests)
		}
	}
	
	public func resetWindow() throws {
		keys.forEach { key in
			Task(priority: .userInitiated) {
				let redisKey = RedisKey(key)
				
				let respValue = try await storage.get(redisKey).get()
			
				var newBucketSize = 0
				
				if let currentBucketSize = respValue.int {
					newBucketSize = currentBucketSize < configuration.tokenRemovingRate ? 0 : (currentBucketSize - configuration.tokenRemovingRate)
				}
				
				try await storage.decrement(redisKey, by: newBucketSize).get()
			}
		}
	}
}
