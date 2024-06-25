//
//  TokenBucketConfiguration.swift
//  
//
//  Created by Adolfo Vera Blasco on 25/6/24.
//

import Foundation

public struct TokenBucketConfiguration: Configuration {
	public private(set) var bucketSize: Int
	public private(set) var refillTokenRate: Int
	public private(set) var refillTimeInterval: TimeWindow
	
	public private(set) var appliedField: Field
	public private(set) var scope: Scope
}

extension TokenBucketConfiguration {
	public init(bucketSize: Int, refillRate: Int, refillTimeInterval: TimeWindow, appliedTo field: Field = .noField, inside scope: Scope = .noScope) {
		self.bucketSize = bucketSize
		self.refillTokenRate = refillRate
		self.refillTimeInterval = refillTimeInterval
		self.appliedField = field
		self.scope = scope
	}
}
