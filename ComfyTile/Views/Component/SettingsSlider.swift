//
//  SettingsSlider.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI

struct SettingsSlider: View {
    let title: String
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    @Binding var showSettings: Bool
    @Binding var isResizing: Bool
    var showBottomLabel: Bool = true

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                Spacer()
                Text(label)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .redacted(reason: !showSettings || isResizing ? .placeholder : [])
            
            /// This allows us to not lag while opening
            if showSettings && !isResizing {
                Slider(value: $value, in: range, step: step)
                    .labelsHidden()
            }
            
            if showBottomLabel {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(range.lowerBound, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(range.upperBound, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .redacted(reason: !showSettings || isResizing ? .placeholder : [])
            }
        }
    }
}
