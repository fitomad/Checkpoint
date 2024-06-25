//
//  FixedWindowCounterConfiguration.swift
//  
//
//  Created by Adolfo Vera Blasco on 25/6/24.
//

import Foundation

public struct FixedWindowCounterConfiguration: Configuration {
	public private(set) var requestPerWindow: Int
	public private(set) var timeWindowDuration: TimeWindow
	
	public private(set) var appliedField: Field
	public private(set) var scope: Scope
}

extension FixedWindowCounterConfiguration {
	public init(requestPerWindow: Int, timeWindowDuration: TimeWindow, appliedTo field: Field = .noField, inside scope: Scope = .noScope) {
		self.requestPerWindow = requestPerWindow
		self.timeWindowDuration = timeWindowDuration
		self.appliedField = field
		self.scope = scope
	}
}
