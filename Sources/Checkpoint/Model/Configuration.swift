//
//  Cinfiguration.swift
//  
//
//  Created by Adolfo Vera Blasco on 19/6/24.
//


public protocol Configuration {
	var appliedField: Field { get }
	var scope: RateLimitScope { get }
}

public struct FixedWindowCounterConfiguration: Configuration {
	public var requestPerWindow = 5
	public var timeWindowDuration: TimeWindow = .seconds(count: 10)
	
	public var appliedField: Field
	public var scope: RateLimitScope
}

public struct LeakingBucketConfiguration: Configuration {
	public var bucketSize = 10
	public var tokenRemovingRate = 5
	public var timeWindowDuration: TimeWindow = .seconds(count: 10)
	
	public var appliedField: Field
	public var scope: RateLimitScope
}

public struct SlidingWindowLogConfiguration: Configuration {
	public var requestPerWindow = 10
	public var timeWindowDuration: TimeWindow
	
	public var appliedField: Field
	public var scope: RateLimitScope
}

public struct TokenBucketConfiguration: Configuration {
	public var bucketSize: Int
	public var refillTokenRate: Int
	public var refillTimeInterval: TimeWindow
	
	public var appliedField: Field
	public var scope: RateLimitScope
}
