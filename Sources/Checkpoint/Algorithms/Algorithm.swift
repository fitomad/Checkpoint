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

public protocol Algorithm: Sendable {
	associatedtype ConfigurationType
	
	var storage: Application.Redis { get }
	var logging: Logger? { get }
	
	init(configuration: () -> ConfigurationType, storage: StorageAction, logging: LoggerAction?)
	
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
		
		let key = String("\(prefix)\(suffix)".hash)
		
		return key
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
