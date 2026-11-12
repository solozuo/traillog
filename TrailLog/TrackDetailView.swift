import SwiftUI
import MapKit

struct TrackDetailView: View {
    @EnvironmentObject private var store: TrackStore
    @Environment(\.dismiss) private var dismiss

    let track: Track

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingRename = false
    @State private var newName = ""
    @State private var showingDeleteConfirmation = false
    @State private var exportURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Map(position: $cameraPosition) {
                    if !track.coordinates.isEmpty {
                        MapPolyline(coordinates: track.coordinates)
                            .stroke(.blue, lineWidth: 3)
                        if let first = track.coordinates.first {
                            Marker(track.name, coordinate: first)
                        }
                        if let last = track.coordinates.last, track.coordinates.count > 1 {
                            Marker("Finish", coordinate: last)
                        }
                    }
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(TrailFormatters.date(track.startDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                StatsGrid(stats: [
                    (title: "Distance", value: TrailFormatters.distance(track.distance), icon: "point.topleft.down.curvedto.point.bottomright.up"),
                    (title: "Duration", value: TrailFormatters.duration(track.duration), icon: "clock"),
                    (title: "Climb", value: TrailFormatters.elevation(track.elevationGain), icon: "arrow.up.right"),
                    (title: "Avg Speed", value: TrailFormatters.speed(track.averageSpeed), icon: "gauge.with.dots.needle.33percent"),
                    (title: "Points", value: "\(track.points.count)", icon: "mappin.and.ellipse"),
                ])
            }
            .padding()
        }
        .navigationTitle(track.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Export GPX", systemImage: "square.and.arrow.up")
                    }
                }
                Menu {
                    Button("Rename") {
                        newName = track.name
                        showingRename = true
                    }
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            exportURL = GPXHandler.exportURL(for: track)
            fitCamera()
        }
        .alert("Rename trail", isPresented: $showingRename) {
            TextField("Trail name", text: $newName)
            Button("Save") {
                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    store.rename(track, to: trimmed)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete this trail?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                store.delete(track)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func fitCamera() {
        guard !track.coordinates.isEmpty else { return }
        let latitudes = track.coordinates.map(\.latitude)
        let longitudes = track.coordinates.map(\.longitude)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
