//
//  Cinfiguration.swift
//  
//
//  Created by Adolfo Vera Blasco on 19/6/24.
//


public protocol Configuration {
	var appliedField: Field { get }
	var scope: Scope { get }
}

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

public struct LeakingBucketConfiguration: Configuration {
	public var bucketSize = 10
	public var tokenRemovingRate = 5
	public var timeWindowDuration: TimeWindow = .seconds(count: 10)
	
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


public struct SlidingWindowLogConfiguration: Configuration {
	public var requestPerWindow = 10
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
