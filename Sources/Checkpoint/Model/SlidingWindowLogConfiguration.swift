//
//  SlidingWindowLogConfiguration.swift
//  
//
//  Created by Adolfo Vera Blasco on 25/6/24.
//

import Foundation

public struct SlidingWindowLogConfiguration: Configuration {
	public var requestPerWindow: Int
	public var timeWindowDuration: TimeWindow
	
	public var appliedField: Field
	public var scope: Scope
}

extension SlidingWindowLogConfiguration {
	public init(requestPerWindow: Int, windowDuration: TimeWindow, appliedTo field: Field = .noField, inside scope: Scope = .noScope) {
		self.requestPerWindow = requestPerWindow
		self.timeWindowDuration = windowDuration
		self.appliedField = field
		self.scope = scope
	}
}
