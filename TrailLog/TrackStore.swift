import Foundation

/// Local-only persistence: all tracks live in one JSON file in Documents.
/// No account, no server, no analytics.
@MainActor
final class TrackStore: ObservableObject {
    @Published private(set) var tracks: [Track] = []

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent("tracks.json")
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([Track].self, from: data) {
            tracks = decoded.sorted { $0.startDate > $1.startDate }
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(tracks) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    func add(_ track: Track) {
        tracks.insert(track, at: 0)
        save()
    }

    func delete(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        save()
    }

    func rename(_ track: Track, to newName: String) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[index].name = newName
        save()
    }
}
