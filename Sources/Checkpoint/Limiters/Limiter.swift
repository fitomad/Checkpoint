//
//  Limiter.swift
//  
//
//  Created by Adolfo Vera Blasco on 14/6/24.
//

import Combine
import Redis
import Vapor

public typealias StorageAction = () -> Application.Redis
public typealias LoggerAction = () -> Logger

public protocol Limiter: Sendable {
	associatedtype ConfigurationType
	
	var storage: Application.Redis { get }
	var logging: Logger? { get }
	
	init(configuration: () -> ConfigurationType, storage: StorageAction, logging: LoggerAction?)
	
	func checkRequest(_ request: Request) async throws
}

extension Limiter {
	func valueFor(field: Field, in request: Request) throws -> String {
		switch field {
			case .header(let key):
				guard let value = request.headers[key].first else {
					throw Abort(.unauthorized, reason: "")
				}
				
				return value
			case .queryItem(let key):
				guard let value = request.query[String.self, at: key] else {
					throw Abort(.unauthorized, reason: "")
				}
				
				return value
			case .none:
				return Self.none
		}
	}
	
	func valueFor(scope: RateLimitScope, in request: Request) throws -> String {
		switch scope {
			case .endpoint:
				return request.url.path
			case .api:
				guard let host = request.url.host else {
					throw Abort(.badRequest, reason: "")
				}
				
				return host
			case .nonScope:
				return Self.nonScope
		}
	}
	
	func valueFor(field: Field, in request: Request, inside scope: RateLimitScope) throws -> String {
		let prefix = try valueFor(field: field, in: request)
		let suffix = try valueFor(scope: scope, in: request)
		
		let key = String("\(prefix)\(suffix)".hash)
		
		return key
	}
}

extension Limiter {
	static var none: String {
		"no-key"
	}
	
	static var nonScope: String {
		"non-scope"
	}
}
