//
//  SlidingWindowLog.swift
//  
//
//  Created by Adolfo Vera Blasco on 15/6/24.
//

import Redis
import Vapor

/// The Sliding Window Log rate-limit algorithim is based on the request count perfomed during a non fixed window time.
/// It works following this workflow:
///
/// 1. When new request comes in remove all outdated timestamps from cache. By outdated we mean timestamps that are older than window size.
/// 2. Add new timestamp to cache.
/// 3. If number of timestamps in cache is greater than limit reject request and return 429 status code.
/// 4. If lower than limit then accept request and return 200 status code.

public final class SlidingWindowLog {
	/// Configuration for the Sliding Window Log
	private let configuration: SlidingWindowLogConfiguration
	/// Redis database where we store the request timestamps
	public let storage: Application.Redis
	/// A Vapor logger object
	public let logging: Logger?
	
	/// Create a new Sliging Window Log with a given configuration, storage and a logger
	///
	/// - Parameters:
	/// - configuration: A `SlidingWindowLogConfiguration` object
	/// - storage: The Redis database instance created on Vapor
	/// - logging: A `Logger` object created on Vapor.
	public init(configuration: () -> SlidingWindowLogConfiguration, storage: StorageAction, logging: LoggerAction? = nil) {
		self.configuration = configuration()
		self.storage = storage()
		self.logging = logging?()
	}
}

extension SlidingWindowLog: Algorithm {	
	public func checkRequest(_ request: Request) async throws {
		guard let apiKey = try? valueFor(field: configuration.appliedField, in: request, inside: configuration.scope) else {
			throw Abort(.unauthorized, reason: Checkpoint.HTTPErrorDescription.unauthorized)
		}
		
		let redisKey = RedisKey(apiKey)
		
		let requestDate = Date()
		let outdatedRequestLimiteDate = Date().addingTimeInterval(-configuration.timeWindowDuration.inSeconds)
		
		// 1. Delete outdated request
		let topBound: Double = Double(outdatedRequestLimiteDate.timeIntervalSinceReferenceDate)
		let deletedEntriesCount = try await storage.zremrangebyscore(from: redisKey, withMaximumScoreOf: RedisZScoreBound(floatLiteral: topBound)).get()
		
		// 2. Add the current request
		let requestTimeInterval = Double(requestDate.timeIntervalSinceReferenceDate)
		try await storage.zadd([ (element: requestTimeInterval, score: requestTimeInterval) ], to: redisKey).get()
		
		// 3. Get the number of request for this time window
		let itemsCount = try await storage.zcount(of: redisKey, withScores: 0.0...requestTimeInterval).get()
		
		// 4. If request count is greater...
		if itemsCount > configuration.requestPerWindow {
			throw Abort(.tooManyRequests)
		}
	}
}
