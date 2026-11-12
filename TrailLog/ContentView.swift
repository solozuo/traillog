import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: TrackStore
    @StateObject private var recorder = LocationRecorder()

    @State private var showingRecorder = false
    @State private var showingImporter = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if recorder.state != .idle {
                    Button {
                        showingRecorder = true
                    } label: {
                        HStack {
                            Image(systemName: "record.circle.fill")
                                .foregroundStyle(.red)
                            Text("Recording… \(TrailFormatters.duration(recorder.elapsed)) · \(TrailFormatters.distance(recorder.distance))")
                                .font(.subheadline)
                            Spacer()
                            Text("View")
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .background(.orange.opacity(0.15))
                }

                List {
                    if store.tracks.isEmpty {
                        ContentUnavailableView(
                            "No trails yet",
                            systemImage: "map",
                            description: Text("Record your first trail or import a GPX file.")
                        )
                    } else {
                        ForEach(store.tracks) { track in
                            NavigationLink {
                                TrackDetailView(track: track)
                            } label: {
                                TrackRowView(track: track)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                store.delete(store.tracks[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("TrailLog")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import GPX", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingRecorder = true
                    } label: {
                        Label("Record a Trail", systemImage: "record.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingRecorder) {
                RecordingView()
                    .environmentObject(store)
                    .environmentObject(recorder)
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.xml, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importGPXFile(at: url)
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
            .alert(
                "Import failed",
                isPresented: Binding(
                    get: { importError != nil },
                    set: { if !$0 { importError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
            .onOpenURL { url in
                importGPXFile(at: url)
            }
        }
    }

    private func importGPXFile(at url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url),
              let track = GPXHandler.parse(data: data) else {
            importError = "Could not read this GPX file."
            return
        }
        store.add(track)
    }
}

struct TrackRowView: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(track.name)
                .font(.headline)
            Text(TrailFormatters.date(track.startDate))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Label(TrailFormatters.distance(track.distance), systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                Label(TrailFormatters.duration(track.duration), systemImage: "clock")
                Label(TrailFormatters.elevation(track.elevationGain), systemImage: "arrow.up.right")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
