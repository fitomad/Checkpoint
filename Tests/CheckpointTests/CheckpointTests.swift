import XCTest
import XCTVapor
@testable import Checkpoint

final class CheckpointTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
	
	func testConfig() {
		let tokenbucketAlgorithm = TokenBucket {
			TokenBucketConfiguration(bucketSize: 10,
									 refillRate: 5,
									 refillTimeInterval: .seconds(count: 2))
		} storage: {
			
		}
		
		let checkpoint = Checkpoint(using: tokenbucketAlgorithm)
		
		checkpoint.willCheck = { (request: Request) in
			
		}
		
		checkpoint.didCheck = { (request: Request) in
			
		}
		
		checkpoint.didFailWithTooManyRequest = { (request: Request, error: Error) in
			
		}
		
		checkpoint.didFail = { (request: Request, error: Error) in
			
		}
	}
}
