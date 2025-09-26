//
//  ContentView.swift
//  ProjectMotion
//
//  Created by Thomas B on 9/25/25.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @AppStorage("needRippleEffect") var needRippleEffect = true
    @AppStorage("needDetailsOnContentView") var needDetailsOnContentView = true
    
    @StateObject private var manager = MotionManager()
    @State private var fileURL: URL?
    @State private var showShareSheet = false
    @State private var ripples: [UUID] = []
    @State private var rippleTimer: Timer?
    @State private var showSettingsSheet: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Render ripples
                if needRippleEffect {
                    ForEach(ripples, id: \.self) { id in
                        RippleView()
                            .onAppear {
                                // Remove each ripple after its animation duration
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    ripples.removeAll { $0 == id }
                                }
                            }
                    }
                }
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Project Motion")
                            .font(.title)
                            .bold()
                            .padding()
                        Spacer()
                        Button(action: {
                            HapticsManager.shared.playHapticFeedback()
                            showSettingsSheet.toggle()
                        }) {
                            Image(systemName: "gear")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding()
                        }
                    }
                    
                    Spacer()
                    
                    Spacer()
                    
                    if needDetailsOnContentView {
                        liveDataView
                            .padding()
                    }
                    
                    HStack(spacing: 20) {
                        Button(manager.isRecording ? "Stop Recording" : "Start Recording") {
                            if manager.isRecording {
                                manager.stopRecording()
                                fileURL = manager.exportFileURL()
                                stopRippleTimer()
                            } else {
                                manager.startRecording()
                                startRippleTimer()
                            }
                            HapticsManager.shared.playHapticFeedback()
                        }
                        .font(.headline)
                        .padding()
                        .background(manager.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        if fileURL != nil {
                            Button("Share CSV") {
                                showShareSheet = true
                                HapticsManager.shared.playHapticFeedback()
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    Spacer()
                    
                    Text("App might need network access, but not external permissions")
                        .font(.caption)
                        .opacity(0.5)
                    Text("© LinecoFlow LAB")
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let fileURL = fileURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
        }
    }
    
    private var liveDataView: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let a = manager.accelData {
                Text("Accel: x=\(a.x, specifier: "%.2f"), y=\(a.y, specifier: "%.2f"), z=\(a.z, specifier: "%.2f")")
            }
            if let g = manager.gyroData {
                Text("Gyro: x=\(g.x, specifier: "%.2f"), y=\(g.y, specifier: "%.2f"), z=\(g.z, specifier: "%.2f")")
            }
            if let m = manager.magData {
                Text("Mag: x=\(m.x, specifier: "%.2f"), y=\(m.y, specifier: "%.2f"), z=\(m.z, specifier: "%.2f")")
            }
            if let att = manager.attitude {
                Text("Attitude: roll=\(att.roll, specifier: "%.2f"), pitch=\(att.pitch, specifier: "%.2f"), yaw=\(att.yaw, specifier: "%.2f")")
            }
        }
        .padding()
    }
    
    // MARK: - Ripple Timer
    
    private func startRippleTimer() {
        rippleTimer?.invalidate()
        rippleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            ripples.append(UUID())
        }
    }
    
    private func stopRippleTimer() {
        rippleTimer?.invalidate()
        rippleTimer = nil
        ripples.removeAll()
    }
}

/// Wrapper for iOS Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct RippleView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: CGFloat = 1.0

    var body: some View {
        Circle()
            .strokeBorder(.blue.opacity(0.5), lineWidth: 3)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    scale = 2.0
                    opacity = 0.0
                }
            }
    }
}

#Preview {
    ContentView()
}
