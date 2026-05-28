//
//  ProfileWithInterests.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/25/26.
//

import SwiftUI
import os.signpost

@Observable
@MainActor
final class ObservedValueHashable: Equatable, Sendable {
    let name: StaticString
    let read: () -> AnyHashable

    init(name: StaticString, read: @escaping () -> AnyHashable) {
        self.name = name
        self.read = read
    }

    static func == (lhs: ObservedValueHashable, rhs: ObservedValueHashable) -> Bool {
        String(describing: lhs.name) == String(describing: rhs.name)
    }
}

@Observable
@MainActor
final class ProfileWithInterests {

    let name: StaticString
    let observedValues: [ObservedValueHashable]

    private var activeSignpostID: OSSignpostID?
    private let log = OSLog.comfyView

    init(name: StaticString, values: ObservedValueHashable...) {
        self.name = name
        self.observedValues = values

        for value in values {
            observe(value: value, for: name)
        }
    }

    @MainActor
    public func observe(value: ObservedValueHashable, for name: StaticString) {
        withObservationTracking {
            _ = value.read()
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }

                if self.activeSignpostID != nil {
                    os_signpost(.event, log: self.log, name: value.name)
                }

                self.observe(value: value, for: name)
            }
        }
    }

    @MainActor
    public func interval<T>(
        _ intervalName: StaticString,
        _ work: () throws -> T
    ) rethrows -> T {
        let id = OSSignpostID(log: log)

        os_signpost(.begin, log: log, name: intervalName, signpostID: id)
        defer {
            os_signpost(.end, log: log, name: intervalName, signpostID: id)
        }

        return try work()
    }

    @MainActor
    public func interval<T>(
        _ intervalName: StaticString,
        _ work: () async throws -> T
    ) async rethrows -> T {
        let id = OSSignpostID(log: log)

        os_signpost(.begin, log: log, name: intervalName, signpostID: id)
        defer {
            os_signpost(.end, log: log, name: intervalName, signpostID: id)
        }

        return try await work()
    }

    func toggleProfiling() {
        if let id = activeSignpostID {
            os_signpost(
                .end,
                log: log,
                name: name,
                signpostID: id
            )

            activeSignpostID = nil
        } else {
            let id = OSSignpostID(log: log)

            os_signpost(
                .begin,
                log: log,
                name: name,
                signpostID: id
            )

            activeSignpostID = id
        }
    }
}
