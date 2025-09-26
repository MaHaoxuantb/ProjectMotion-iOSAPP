//
//  MotionStorage.swift
//  ProjectMotion
//
//  Created by Thomas B on 9/25/25.
//

import Foundation

/// Handles storing and exporting motion data
class MotionStorage {
    private var recordedData: [String] = []
    private let queue = DispatchQueue(label: "com.projectmotion.storage", qos: .utility)
    
    init() {
        recordedData.removeAll()
        recordedData.append("TYPE,TIMESTAMP,X,Y,Z") // CSV header
    }
    
    func store(type: String, timestamp: TimeInterval, values: [Double]) {
        // Validate input data
        guard values.count == 3 else {
            print("⚠️ Invalid values count for \(type): expected 3, got \(values.count)")
            return
        }
        
        // Check for invalid values
        let validValues = values.map { value in
            if value.isNaN || value.isInfinite {
                print("⚠️ Invalid sensor value detected: \(value)")
                return 0.0 // Replace with 0 or skip this reading
            }
            return value
        }
        
        // Thread-safe storage
        queue.async { [weak self] in
            let formattedValues = validValues.map { String(format: "%.6f", $0) }
            let line = "\(type),\(String(format: "%.6f", timestamp)),\(formattedValues.joined(separator: ","))"
            self?.recordedData.append(line)
        }
    }
    
    func saveToFile() -> URL? {
        var dataToSave: [String] = []
        
        // Thread-safe read
        queue.sync {
            dataToSave = self.recordedData
        }
        
        let joined = dataToSave.joined(separator: "\n")
        guard let dir = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask).first else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "motion_data_\(timestamp).csv"
        let fileURL = dir.appendingPathComponent(filename)
        
        do {
            try joined.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Saved \(dataToSave.count - 1) data points to \(filename)")
            return fileURL
        } catch {
            print("❌ Save failed: \(error)")
            return nil
        }
    }
    
    func getRecordCount() -> Int {
        var count = 0
        queue.sync {
            count = max(0, recordedData.count - 1) // Subtract header
        }
        return count
    }
}
