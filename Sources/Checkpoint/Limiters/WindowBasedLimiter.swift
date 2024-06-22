//
//  WindowBasedLimiter.swift
//  
//
//  Created by Adolfo Vera Blasco on 17/6/24.
//

import Combine
import Foundation

public typealias WindowBasedAction = () throws -> Void

public protocol WindowBasedLimiter: Limiter {
	func startWindow(havingDuration seconds: Double, performing action: @escaping WindowBasedAction) -> AnyCancellable
	func resetWindow() async throws
}

extension WindowBasedLimiter {
	public func startWindow(havingDuration seconds: Double, performing action: @escaping WindowBasedAction) -> AnyCancellable {
		var cancellable = Timer.publish(every: seconds, on: .main, in: .common)
			.autoconnect()
			.sink { _ in
				do {
					try action()
				} catch let timerError {
					self.logging?.error("🚨 Something wrong at timer: \(timerError.localizedDescription)")
				}
			}
		
		return cancellable
	}
}

