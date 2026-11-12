import Foundation
import CoreLocation

/// One recorded GPS sample.
struct TrackPoint: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    var speed: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.altitude
        timestamp = location.timestamp
        speed = max(0, location.speed)
    }

    init(latitude: Double, longitude: Double, altitude: Double, timestamp: Date, speed: Double = 0) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.speed = speed
    }
}

/// A complete recorded trail. Distance, climb and duration are computed
/// once when the recording stops and stored with the track.
struct Track: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var startDate: Date
    var points: [TrackPoint]
    var distance: Double      // meters
    var elevationGain: Double // meters
    var duration: TimeInterval // seconds

    var coordinates: [CLLocationCoordinate2D] {
        points.map(\.coordinate)
    }

    var endDate: Date {
        points.last?.timestamp ?? startDate
    }

    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return distance / duration
    }
}
