//
//  LeakingBucketConfiguration.swift
//  
//
//  Created by Adolfo Vera Blasco on 25/6/24.
//

import Foundation

public struct LeakingBucketConfiguration: Configuration {
	public var bucketSize: Int
	public var tokenRemovingRate: Int
	public var timeWindowDuration: TimeWindow
	
	public var appliedField: Field
	public var scope: Scope
}

extension LeakingBucketConfiguration {
	public init(bucketSize: Int, removingRate: Int, removingTimeInterval: TimeWindow, appliedTo field: Field = .noField, inside scope: Scope = .noScope) {
		self.bucketSize = bucketSize
		self.tokenRemovingRate = removingRate
		self.timeWindowDuration = removingTimeInterval
		self.appliedField = field
		self.scope = scope
	}
}
