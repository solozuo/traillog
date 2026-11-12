import Foundation

/// GPX export and import. No dependencies, plain XML.
enum GPXHandler {

    // MARK: Export

    static func gpxString(for track: Track) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<gpx version=\"1.1\" creator=\"TrailLog\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        xml += "  <metadata><name>\(escape(track.name))</name><time>\(iso.string(from: track.startDate))</time></metadata>\n"
        xml += "  <trk>\n    <name>\(escape(track.name))</name>\n    <trkseg>\n"
        for point in track.points {
            xml += "      <trkpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\"><ele>\(point.altitude)</ele><time>\(iso.string(from: point.timestamp))</time></trkpt>\n"
        }
        xml += "    </trkseg>\n  </trk>\n</gpx>\n"
        return xml
    }

    /// Writes the track to a temporary .gpx file and returns its URL,
    /// ready to hand to a ShareLink. Returns nil on failure.
    static func exportURL(for track: Track) -> URL? {
        let fileName = sanitizedFileName(track.name) + ".gpx"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard let data = gpxString(for: track).data(using: .utf8) else { return nil }
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    static func sanitizedFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "TrailLog" : cleaned
    }

    static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: Import

    static func parse(data: Data) -> Track? {
        GPXParser().parse(data: data)
    }
}

/// Minimal streaming GPX parser: reads trkpt lat/lon, ele and time.
/// Distance is recomputed with the haversine formula, climb with the
/// same 2 m noise threshold used while recording.
final class GPXParser: NSObject, XMLParserDelegate {
    private var points: [TrackPoint] = []
    private var trackName = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double?
    private var currentTime: Date?
    private var currentElement = ""
    private var foundCharacters = ""

    private let iso = ISO8601DateFormatter()
    private let isoFractional = ISO8601DateFormatter()

    override init() {
        iso.formatOptions = [.withInternetDateTime]
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        super.init()
    }

    func parse(data: Data) -> Track? {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        guard xmlParser.parse(), !points.isEmpty else { return nil }

        let start = points.first?.timestamp ?? Date()
        let end = points.last?.timestamp ?? start
        var distance = 0.0
        var gain = 0.0
        var lastAlt: Double?
        for (index, point) in points.enumerated() {
            if index > 0 {
                distance += haversine(from: points[index - 1], to: point)
            }
            if let last = lastAlt {
                let delta = point.altitude - last
                if delta > 2 { gain += delta }
            }
            lastAlt = point.altitude
        }
        let name = trackName.isEmpty ? "Imported Trail" : trackName
        return Track(
            id: UUID(),
            name: name,
            startDate: start,
            points: points,
            distance: distance,
            elevationGain: gain,
            duration: end.timeIntervalSince(start)
        )
    }

    private func haversine(from a: TrackPoint, to b: TrackPoint) -> Double {
        let radius = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * radius * asin(min(1, sqrt(h)))
    }

    private func parseTime(_ text: String) -> Date? {
        iso.date(from: text) ?? isoFractional.date(from: text)
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        foundCharacters = ""
        if elementName == "trkpt" {
            currentLat = Double(attributeDict["lat"] ?? "")
            currentLon = Double(attributeDict["lon"] ?? "")
            currentEle = nil
            currentTime = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        foundCharacters += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "ele":
            currentEle = Double(text)
        case "time":
            currentTime = parseTime(text)
        case "name":
            if trackName.isEmpty { trackName = text }
        case "trkpt":
            if let lat = currentLat, let lon = currentLon {
                points.append(TrackPoint(
                    latitude: lat,
                    longitude: lon,
                    altitude: currentEle ?? 0,
                    timestamp: currentTime ?? Date(),
                    speed: 0
                ))
            }
        default:
            break
        }
        foundCharacters = ""
    }
}
