//
//  Cinfiguration.swift
//  
//
//  Created by Adolfo Vera Blasco on 19/6/24.
//


protocol Configuration {
	var appliedField: Field { get }
	var scope: RateLimitScope { get }
}

struct FixedWindowCounterConfiguration: Configuration {
	var requestPerWindow = 5
	var timeWindowDuration: TimeWindow = .seconds(count: 10)
	
	var appliedField: Field
	var scope: RateLimitScope
}

struct LeakingBucketConfiguration: Configuration {
	var bucketSize = 10
	var tokenRemovingRate = 5
	var timeWindowDuration: TimeWindow = .seconds(count: 10)
	
	var appliedField: Field
	var scope: RateLimitScope
}

struct SlidingWindowLogConfiguration: Configuration {
	var requestPerWindow = 10
	var timeWindowDuration: TimeWindow
	
	var appliedField: Field
	var scope: RateLimitScope
}

struct TokenBucketConfiguration: Configuration {
	var bucketSize: Int
	var refillRate: Int
	var refillTimeInterval: TimeWindow
	
	var appliedField: Field
	var scope: RateLimitScope
}
