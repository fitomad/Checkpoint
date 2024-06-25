//
//  WindowBasedLimiter.swift
//  
//
//  Created by Adolfo Vera Blasco on 17/6/24.
//

import Combine
import Foundation

public typealias WindowBasedAction = () throws -> Void

/// For those algorithims thar works with fixed time windows.
public protocol WindowBasedAlgorithm: Algorithm {
	/// Start the timer for a given duration (time window)
	func startWindow(havingDuration seconds: Double, performing action: @escaping WindowBasedAction) -> AnyCancellable
	/// Perfomrs the reset operation when the time windo ends.
	func resetWindow() async throws
}

extension WindowBasedAlgorithm {
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

