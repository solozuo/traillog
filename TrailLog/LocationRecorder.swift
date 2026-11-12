import Foundation
import CoreLocation

/// Owns the CLLocationManager and accumulates a recording.
/// Background location is enabled so recording continues while the
/// phone is locked; the recorder itself lives in ContentView so it
/// survives the recording sheet being hidden.
@MainActor
final class LocationRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    enum State {
        case idle
        case recording
        case paused
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var points: [TrackPoint] = []
    @Published private(set) var distance: Double = 0          // meters
    @Published private(set) var elevationGain: Double = 0     // meters
    @Published private(set) var currentSpeed: Double = 0      // m/s
    @Published private(set) var elapsed: TimeInterval = 0     // seconds
    @Published private(set) var authorizationDenied = false

    var averageSpeed: Double {
        guard elapsed > 0 else { return 0 }
        return distance / elapsed
    }

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastAltitude: Double?
    private var startTime: Date?
    private var accumulatedElapsed: TimeInterval = 0
    private var timer: Timer?

    /// Positive altitude steps smaller than this are treated as GPS noise.
    private let elevationNoiseThreshold = 2.0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func start() {
        points = []
        distance = 0
        elevationGain = 0
        currentSpeed = 0
        elapsed = 0
        lastLocation = nil
        lastAltitude = nil
        accumulatedElapsed = 0
        startTime = Date()
        startTimer()
        manager.startUpdatingLocation()
        state = .recording
    }

    func pause() {
        guard state == .recording else { return }
        accumulatedElapsed += Date().timeIntervalSince(startTime ?? Date())
        elapsed = accumulatedElapsed
        timer?.invalidate()
        manager.stopUpdatingLocation()
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        // Drop the last fix so the pause gap is not counted as distance.
        lastLocation = nil
        startTime = Date()
        startTimer()
        manager.startUpdatingLocation()
        state = .recording
    }

    /// Stops the recording and returns the finished track, or nil if
    /// nothing was recorded.
    func stop() -> Track? {
        guard state != .idle else { return nil }
        timer?.invalidate()
        manager.stopUpdatingLocation()
        let totalElapsed: TimeInterval
        if state == .recording {
            totalElapsed = accumulatedElapsed + Date().timeIntervalSince(startTime ?? Date())
        } else {
            totalElapsed = accumulatedElapsed
        }
        elapsed = totalElapsed
        state = .idle
        guard !points.isEmpty else { return nil }
        return Track(
            id: UUID(),
            name: defaultTrackName(),
            startDate: points.first?.timestamp ?? Date(),
            points: points,
            distance: distance,
            elevationGain: elevationGain,
            duration: totalElapsed
        )
    }

    private func defaultTrackName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return "Trail \(formatter.string(from: Date()))"
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.elapsed = self.accumulatedElapsed + Date().timeIntervalSince(self.startTime ?? Date())
            }
        }
    }

    private func handleLocations(_ locations: [CLLocation]) {
        guard state == .recording else { return }
        for location in locations {
            // Drop fixes with no usable accuracy.
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { continue }
            if let last = lastLocation {
                distance += location.distance(from: last)
            }
            if let lastAlt = lastAltitude {
                let delta = location.altitude - lastAlt
                if delta > elevationNoiseThreshold {
                    elevationGain += delta
                }
            }
            lastAltitude = location.altitude
            lastLocation = location
            points.append(TrackPoint(location: location))
            currentSpeed = max(0, location.speed)
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.handleLocations(locations)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            self.authorizationDenied = (status == .denied || status == .restricted)
        }
    }
}
