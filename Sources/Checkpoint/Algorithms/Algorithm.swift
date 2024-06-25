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

/// Definition for the different Rate-Limit algorithims
public protocol Algorithm: Sendable {
	/// The configuration type used in a specific algorithim
	associatedtype ConfigurationType
	
	/// The Redis database used to store the request data
	var storage: Application.Redis { get }
	/// A `Logger` object created on Vapor
	var logging: Logger? { get }
	
	/// Create a new Rate-Limit algorithim with a given configuration,
	/// storage and logging
	init(configuration: () -> ConfigurationType, storage: StorageAction, logging: LoggerAction?)
	
	/// Performs the algorithim logic to check if a request is valid
	/// or reach the rate-limit specified on the algorithim's configuration
	func checkRequest(_ request: Request) async throws
}

extension Algorithm {
	func valueFor(field: Field, in request: Request) throws -> String {
		switch field {
			case .header(let key):
				guard let value = request.headers[key].first else {
					throw Abort(.unauthorized, reason: Self.noFieldMessage)
				}
				
				return value
			case .queryItem(let key):
				guard let value = request.query[String.self, at: key] else {
					throw Abort(.unauthorized, reason: Self.noFieldMessage)
				}
				
				return value
			case .noField:
				return Self.fieldDefaultKey
		}
	}
	
	func valueFor(scope: Scope, in request: Request) throws -> String {
		switch scope {
			case .endpoint:
				return request.url.path
			case .api:
				guard let host = request.url.host else {
					throw Abort(.badRequest, reason: Self.hostNotFoundMessage)
				}
				
				return host
			case .noScope:
				return Self.scopeDefaultKey
		}
	}
	
	func valueFor(field: Field, in request: Request, inside scope: Scope) throws -> String {
		let prefix = try valueFor(field: field, in: request)
		let suffix = try valueFor(scope: scope, in: request)
		
		var hasher = Hasher()
		hasher.combine(prefix)
		hasher.combine(suffix)
		
		let key = hasher.finalize()
		
		return String(key)
	}
}

extension Algorithm {
	static var fieldDefaultKey: String {
		"checkpoint#no.field"
	}
	
	static var scopeDefaultKey: String {
		"checkpoint#no.scope"
	}
	
	static var noFieldMessage: String {
		"Expected field not found at headers or query parameters"
	}
	
	static var hostNotFoundMessage: String {
		"Unable to recover host from request"
	}
}
