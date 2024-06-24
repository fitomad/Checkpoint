//
//  SlidingWindowLog.swift
//  
//
//  Created by Adolfo Vera Blasco on 15/6/24.
//

import Redis
import Vapor

public final class SlidingWindowLog {
	private let configuration: SlidingWindowLogConfiguration
	public let storage: Application.Redis
	public let logging: Logger?
	
	public init(configuration: () -> SlidingWindowLogConfiguration, storage: StorageAction, logging: LoggerAction? = nil) {
		self.configuration = configuration()
		self.storage = storage()
		self.logging = logging?()
	}
}

extension SlidingWindowLog: Algorithm {	
	var isValidRequest: Bool {
		return true
	}
	
	public func checkRequest(_ request: Request) async throws {
		guard let apiKey = try? valueFor(field: configuration.appliedField, in: request, inside: configuration.scope) else {
			throw Abort(.unauthorized, reason: Checkpoint.HTTPErrorDescription.unauthorized)
		}
		
		logging?.info("💡 ApiKey: \(apiKey)")
		let redisKey = RedisKey(apiKey)
		
		let requestDate = Date()
		let outdatedRequestLimiteDate = Date().addingTimeInterval(-configuration.timeWindowDuration.inSeconds)
		
		// 1. Delete outdated request
		let topBound: Double = Double(outdatedRequestLimiteDate.timeIntervalSinceReferenceDate)
		let deletedEntriesCount = try await storage.zremrangebyscore(from: redisKey, withMaximumScoreOf: RedisZScoreBound(floatLiteral: topBound)).get()
		logging?.info("🆑 Deleted \(deletedEntriesCount) items for api key \"\(apiKey)\"")
		
		// 2. Add the current request
		let requestTimeInterval = Double(requestDate.timeIntervalSinceReferenceDate)
		try await storage.zadd([ (element: requestTimeInterval, score: requestTimeInterval) ], to: redisKey).get()
		logging?.info("💡 Element: \(requestTimeInterval) Score: \(requestTimeInterval)")
		
		// 3. Get the number of request for this time window
		let itemsCount = try await storage.zcount(of: redisKey, withScores: 0.0...requestTimeInterval).get()
		logging?.info("💡 Current items: \(itemsCount)")

		// 4. If request count is greater...
		if itemsCount > configuration.requestPerWindow {
			throw Abort(.tooManyRequests)
		}
	}
}
