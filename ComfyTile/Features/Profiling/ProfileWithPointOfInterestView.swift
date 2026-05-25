//
//  ProfileWithPointOfInterestView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/25/26.
//

import SwiftUI
import os.signpost


struct ObservedValue: Equatable, Sendable {
    let name: StaticString
    let value: AnyHashable

    init(name: StaticString, value: AnyHashable) {
        self.name = name
        self.value = value
    }

    static func == (lhs: ObservedValue, rhs: ObservedValue) -> Bool {
        String(describing: lhs.name) == String(describing: rhs.name) && lhs.value == rhs.value
    }
}

// MARK: - Profile With Points Of Interest
struct ProfileWithPointOfInterestView<Content: View>: View {

    let observedValues: [ObservedValue]
    @ViewBuilder let view: () -> Content

    init(values: ObservedValue..., @ViewBuilder view: @escaping () -> Content) {
        self.observedValues = values
        self.view = view
    }

    @State private var activeSignpostID: OSSignpostID?
    let log = OSLog.comfyView

    var body: some View {
        VStack {
            controls

            view()
        }
        .onChange(of: observedValues) { oldValues, newValues in
            guard activeSignpostID != nil else { return }

            for newValue in newValues {
                let oldValue = oldValues.first {
                    String(describing: $0.name) == String(describing: newValue.name)
                }

                if oldValue?.value != newValue.value {
                    os_signpost(.event, log: log, name: newValue.name)
                }
            }
        }
    }

    @ViewBuilder
    var controls: some View {
        Button(activeSignpostID == nil ? "Start Profiling" : "Stop Profiling") {
            toggleProfiling()
        }
    }

    func toggleProfiling() {
        if let id = activeSignpostID {
            os_signpost(
                .end,
                log: log,
                name: "ManualMeasurement",
                signpostID: id
            )

            activeSignpostID = nil
        } else {
            let id = OSSignpostID(log: log)

            os_signpost(
                .begin,
                log: log,
                name: "ManualMeasurement",
                signpostID: id
            )

            activeSignpostID = id
        }
    }
}

