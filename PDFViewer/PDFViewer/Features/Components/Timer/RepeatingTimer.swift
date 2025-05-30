//
//  RepeatingTimer.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 30/5/25.
//

import Foundation
import Combine

final class RepeatingTimer {
    private var cancellable: AnyCancellable?
    private let interval: TimeInterval
    private let onTick: () -> Void

    init(interval: TimeInterval, onTick: @escaping () -> Void) {
        self.interval = interval
        self.onTick = onTick
    }

    func start() {
        stop() // Ensure no multiple subscriptions
        cancellable = Timer
            .publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.onTick()
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }

    deinit {
        stop()
    }
}
