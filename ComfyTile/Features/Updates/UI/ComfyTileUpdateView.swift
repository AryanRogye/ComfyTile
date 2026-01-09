//
//  ComfyTileUpdateView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/8/26.
//

import SwiftUI
import Sparkle

/// Shown in MenuBar
struct ComfyTileUpdateView: View {
    @Bindable var updateController: UpdateController
    
    var body: some View {
        UpdateBar(updaterVM: updateController.updaterVM)
    }
}

private struct UpdateBar: View {
    @Bindable var updaterVM: UpdaterViewModel
    @State private var showUpdatePopover = false
    
    var body: some View {
        switch updaterVM.phase {
            
        case .idle:
            EmptyView()
            
        case .permissionRequest:
            PermissionRow(updaterVM: updaterVM)
            
        case .checkingUserInitiated:
            /// Will See in Settings
            EmptyView()
            
        case .updateFound(let appcast, let state):
            Button {
                showUpdatePopover.toggle()
            } label: {
                BannerRow {
                    Text("New Update Found")
                    Spacer()
                    Text(appcast.displayVersionString)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showUpdatePopover, arrowEdge: .bottom) {
                UpdateDetailPopover(
                    updaterVM: updaterVM,
                    appcast: appcast,
                    updateState: state,
                    onClose: { showUpdatePopover = false }
                )
            }
            
        case .downloading(let progress, let total):
            BannerRow {
                UpdateRing(progress: Double(progress) / Double(total ?? max(progress, 1)))
            }
            
        case .extracting(let progress):
            BannerRow {
                if let progress {
                    UpdateRing(progress: progress)
                } else {
                    UpdateRing(progress: nil)
                }
            }
            
        case .installing:
            BannerRow {
                HStack {
                    ProgressView()
                    Text("Installing…")
                    Spacer()
                }
            }
            
        case .noUpdate(let msg):
            BannerRow {
                HStack {
                    Text(msg)
                    Spacer()
                    Button("OK") { updaterVM.resetUpdateUI() }
                        .controlSize(.small)
                }
            }
            
        case .error(let msg):
            BannerRow {
                HStack {
                    Text("Update Error: \(msg)")
                    Spacer()
                    Button("OK") { updaterVM.resetUpdateUI() }
                        .controlSize(.small)
                }
            }
        }
    }
}

struct UpdateRing: View {
    let progress: Double?   // nil = indeterminate
    
    @State private var spin = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 4)
            
            if let p = progress {
                Circle()
                    .trim(from: 0, to: max(0, min(1, p)))
                    .stroke(.white, style: .init(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.15), value: p)
            } else {
                Circle()
                    .trim(from: 0.15, to: 0.55)
                    .stroke(.white, style: .init(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .onAppear { spin = true }
                    .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: spin)
            }
        }
        .frame(width: 18, height: 18)
    }
}
private struct BannerRow<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        HStack {
            content
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor)
        }
    }
}

private struct UpdateDetailPopover: View {
    @Bindable var updaterVM: UpdaterViewModel
    let appcast: SUAppcastItem
    let updateState: SPUUserUpdateState
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update Available").font(.headline)
            
            Text("Version: \(appcast.displayVersionString)")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("Build: \(appcast.versionString)")
                .font(.subheadline).foregroundStyle(.secondary)
            
            if appcast.isCriticalUpdate {
                Label("Critical Update", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            
            if let url = appcast.releaseNotesURL {
                Link("Release Notes", destination: url)
            }
            
            Divider()
            
            HStack {
                Button("Skip") { onClose(); updaterVM.completeUpdateFound(choice: .skip) }
                    .controlSize(.small)
                Button("Later") { onClose(); updaterVM.completeUpdateFound(choice: .dismiss) }
                    .controlSize(.small)
                Spacer()
                Button("Install") { onClose(); updaterVM.completeUpdateFound(choice: .install) }
            }
        }
        .padding()
        .frame(width: 220)
    }
}

private struct PermissionRow: View {
    @Bindable var updaterVM: UpdaterViewModel
    @State private var checkForUpdatesAutomatically = false
    
    var body: some View {
        HStack {
            Text("Check For Updates Automatically?")
            Toggle("", isOn: $checkForUpdatesAutomatically)
                .labelsHidden()
                .toggleStyle(.switch)
            Spacer()
            Button("Submit") {
                updaterVM.completePermission(automaticUpdateChecks: checkForUpdatesAutomatically)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(8)
    }
}

#Preview {
    
    @Previewable @State var defaultsManager = DefaultsManager()
    @Previewable @State var fetchedWindowManager = FetchedWindowManager()
    @Previewable @State var updateController = UpdateController()
    
    lazy var settingsCoordinator = SettingsCoordinator(
        windowCoordinator: WindowCoordinator(),
        updateController: updateController,
        defaultsManager: defaultsManager
    )
    
    ComfyTileMenuBarRootView(
        defaultsManager: defaultsManager,
        fetchedWindowManager: fetchedWindowManager,
        settingsCoordinator: settingsCoordinator,
        updateController: updateController,
    )
}
