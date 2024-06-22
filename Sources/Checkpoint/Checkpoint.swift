//
//  RateLimitMiddleware.swift
//  
//
//  Created by Adolfo Vera Blasco on 13/6/24.
//

import Redis
import Vapor

final class Checkpoint {
	let algorithm: any Algorithm
	
	init(using algorithm: some Algorithm) {
		self.algorithm = algorithm
	}
}

extension Checkpoint: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		algorithm.logging?.info("👉 RateLimitMiddleware request")
		let response = try await next.respond(to: request)
		algorithm.logging?.info("👈 RateLimitMiddleware reponse")
		
		do {
			try await checkRateLimitFor(request: request)
			response.headers.add(name: "X-App-Version", value: "v1.0.0")
			algorithm.logging?.info("💡 Header Setted.")
		} catch let abort as AbortError {
			throw abort
		} catch {
			response.headers.add(name: "X-Rate-Limit", value: "8")
			algorithm.logging?.info("🚨 Header Setted.")
			throw Abort(.tooManyRequests,
						headers: response.headers,
						reason: HTTPErrorDescription.rateLimitReached)
		}

		return response
	}
	
	private func checkRateLimitFor(request: Request) async throws {
		try await algorithm.checkRequest(request)
	}
}

extension Checkpoint {
	enum Constants {
		static let apiKeyHeader = "X-ApiKey"
		static let rateLimitDB = "rate-limit"
	}
	
	enum HTTPErrorDescription {
		static let unauthorized = "X-Api-Key header not available in the request"
		static let rateLimitReached = "You have exceed your ApiKey network requests rate"
	}
}

extension Checkpoint {
	/*
	enum Strategy {
		case tokenBucket(configuration: TokenBucket.Configuration)
		case leakingBucket(configuration: LeakingBucket.Configuration)
		case fixedWindowCounter(configuration: FixedWindowCounter.Configuration)
		case slidingWindowLog(configuration: SlidingWindowLog.Configuration)
	}
	*/
	
}

enum Strategy {
	case tokenBucket
	case leakingBucket
	case fixedWindowCounter
	case slidingWindowLog
}
