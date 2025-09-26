//
//  MotionManager.swift
//  ProjectMotion
//
//  Created by Thomas B on 9/25/25.
//

import Foundation
import CoreMotion
import Combine
import SwiftUI

/// Responsible for reading motion sensor data & sending to server
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var accelData: CMAcceleration?
    @Published var gyroData: CMRotationRate?
    @Published var magData: CMMagneticField?
    @Published var attitude: CMAttitude?
    
    @Published var isRecording = false
    private var storage: MotionStorage?
    
    // Counters to limit network frequency
    private var sendCounters: [String: Int] = ["ACC": 0, "GYRO": 0, "MAG": 0, "MOTION": 0]
    private let sendInterval = 5   // send every 5th sample
    
    // ServerURL
    @AppStorage("RTDataServerURL") private var serverURLString: String = "http://192.168.0.102:8000/api"
    private var serverURL: URL? {
        URL(string: serverURLString)
    }
    
    // MARK: - Recording
    
    func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        storage = MotionStorage()   // reset storage
        sendCounters = ["ACC": 0, "GYRO": 0, "MAG": 0, "MOTION": 0]
        
        sendStartSignal()
        
        startAccelerometer()
        startGyroscope()
        startMagnetometer()
        startDeviceMotion()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        stopAll()
        
        sendStopSignal()
    }
    
    func exportFileURL() -> URL? {
        storage?.saveToFile()
    }
    
    // MARK: - Networking
    
    private func sendStartSignal() {
        sendToServer(payload: ["event": "start"])
    }
    
    private func sendStopSignal() {
        sendToServer(payload: ["event": "stop"])
    }
    
    private func sendToServer(type: String, timestamp: TimeInterval, values: [Double]) {
        let payload: [String: Any] = [
            "event": "data",
            "type": type,
            "timestamp": timestamp,
            "values": values
        ]
        sendToServer(payload: payload)
    }
    
    private func sendToServer(payload: [String: Any]) {
        guard let url = serverURL else {
            print("⚠️ No server URL set in RTDataServerURL")
            return
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            URLSession.shared.dataTask(with: request) { _, _, error in
                if let error = error {
                    print("❌ Failed to send data: \(error)")
                }
            }.resume()
        } catch {
            print("❌ JSON error: \(error)")
        }
    }
    
    // Helper: store + optionally send every Nth sample
    private func storeAndMaybeSend(type: String, timestamp: TimeInterval, values: [Double]) {
        storage?.store(type: type, timestamp: timestamp, values: values)
        
        sendCounters[type, default: 0] += 1
        if sendCounters[type, default: 0] % sendInterval == 0 {
            sendToServer(type: type, timestamp: timestamp, values: values)
        }
    }
    
    // MARK: - Private Sensor Functions
    
    private func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            if let d = data {
                DispatchQueue.main.async {
                    self?.accelData = d.acceleration
                    self?.storeAndMaybeSend(type: "ACC",
                                            timestamp: d.timestamp,
                                            values: [d.acceleration.x, d.acceleration.y, d.acceleration.z])
                }
            }
        }
    }
    
    private func startGyroscope() {
        guard motionManager.isGyroAvailable else { return }
        motionManager.startGyroUpdates(to: queue) { [weak self] data, _ in
            if let d = data {
                DispatchQueue.main.async {
                    self?.gyroData = d.rotationRate
                    self?.storeAndMaybeSend(type: "GYRO",
                                            timestamp: d.timestamp,
                                            values: [d.rotationRate.x, d.rotationRate.y, d.rotationRate.z])
                }
            }
        }
    }
    
    private func startMagnetometer() {
        guard motionManager.isMagnetometerAvailable else { return }
        motionManager.startMagnetometerUpdates(to: queue) { [weak self] data, _ in
            if let d = data {
                DispatchQueue.main.async {
                    self?.magData = d.magneticField
                    self?.storeAndMaybeSend(type: "MAG",
                                            timestamp: d.timestamp,
                                            values: [d.magneticField.x, d.magneticField.y, d.magneticField.z])
                }
            }
        }
    }
    
    private func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
            if let d = data {
                DispatchQueue.main.async {
                    self?.attitude = d.attitude
                    self?.storeAndMaybeSend(type: "MOTION",
                                            timestamp: d.timestamp,
                                            values: [d.attitude.roll, d.attitude.pitch, d.attitude.yaw])
                }
            }
        }
    }
    
    private func stopAll() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
}
