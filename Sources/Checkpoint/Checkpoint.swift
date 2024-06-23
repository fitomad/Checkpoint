//
//  RateLimitMiddleware.swift
//  
//
//  Created by Adolfo Vera Blasco on 13/6/24.
//

import Redis
import Vapor

public typealias CheckpointAction = (Request) -> Void
public typealias CheckpointErrorAction = (Request, Response, Error) -> Void

public final class Checkpoint {
	private let algorithm: any Algorithm
	
	public var willCheck: CheckpointAction?
	public var didCheck: CheckpointAction?
	public var didFailWithTooManyRequest: CheckpointErrorAction?
	public var didFail: CheckpointErrorAction?
	
	public init(using algorithm: some Algorithm) {
		self.algorithm = algorithm
	}
}

extension Checkpoint: AsyncMiddleware {
	public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		let response = try await next.respond(to: request)
		
		do {
			willCheck?(request)
			try await checkRateLimitFor(request: request)
			didCheck?(request)
		} catch let abort as AbortError {
			switch abort.status {
				case .tooManyRequests:
					didFailWithTooManyRequest?(request, response, abort)
				default:
					didFail?(request, response, abort)
			}
			
			throw abort
		}

		return response
	}
	
	private func checkRateLimitFor(request: Request) async throws {
		try await algorithm.checkRequest(request)
	}
}

extension Checkpoint {
	enum HTTPErrorDescription {
		static let unauthorized = "X-Api-Key header not available in the request"
		static let rateLimitReached = "You have exceed your ApiKey network requests rate"
	}
}
