import Foundation

/// Plain display formatting for distances, times and speeds.
enum TrailFormatters {
    static func distance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.2f km", meters / 1000)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// Meters per second shown as km/h.
    static func speed(_ metersPerSecond: Double) -> String {
        String(format: "%.1f km/h", max(0, metersPerSecond) * 3.6)
    }

    static func elevation(_ meters: Double) -> String {
        String(format: "%.0f m", meters)
    }

    static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
