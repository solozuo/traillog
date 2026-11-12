import SwiftUI
import MapKit

struct RecordingView: View {
    @EnvironmentObject private var store: TrackStore
    @EnvironmentObject private var recorder: LocationRecorder
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition = MapCameraPosition.userLocation(followsHeading: false, fallback: .automatic)
    @State private var showingStopConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $cameraPosition) {
                    if recorder.points.count > 1 {
                        MapPolyline(coordinates: recorder.points.map(\.coordinate))
                            .stroke(.blue, lineWidth: 3)
                    }
                    UserAnnotation()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }

                VStack(spacing: 12) {
                    StatsGrid(stats: [
                        (title: "Time", value: TrailFormatters.duration(recorder.elapsed), icon: "clock"),
                        (title: "Distance", value: TrailFormatters.distance(recorder.distance), icon: "point.topleft.down.curvedto.point.bottomright.up"),
                        (title: "Climb", value: TrailFormatters.elevation(recorder.elevationGain), icon: "arrow.up.right"),
                        (title: "Avg Speed", value: TrailFormatters.speed(recorder.averageSpeed), icon: "gauge.with.dots.needle.33percent"),
                        (title: "Current", value: TrailFormatters.speed(recorder.currentSpeed), icon: "speedometer"),
                    ])

                    controls

                    if recorder.state != .idle {
                        Text("Recording continues in the background if you hide this screen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial)
            }
            .navigationTitle("Record Trail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hide") { dismiss() }
                }
            }
            .onAppear {
                recorder.requestAuthorization()
            }
            .alert("Stop and save this trail?", isPresented: $showingStopConfirmation) {
                Button("Save") { saveAndClose() }
                Button("Discard", role: .destructive) { discardAndClose() }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Location access needed",
                isPresented: Binding(
                    get: { recorder.authorizationDenied },
                    set: { _ in }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("TrailLog needs location access to record a trail. Turn it on in Settings > Privacy & Security > Location Services.")
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch recorder.state {
        case .idle:
            Button {
                recorder.start()
            } label: {
                Label("Start Recording", systemImage: "record.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        case .recording:
            HStack {
                Button {
                    recorder.pause()
                } label: {
                    Label("Pause", systemImage: "pause.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Button {
                    showingStopConfirmation = true
                } label: {
                    Label("Stop", systemImage: "stop.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.red)
            }
        case .paused:
            HStack {
                Button {
                    recorder.resume()
                } label: {
                    Label("Resume", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button {
                    showingStopConfirmation = true
                } label: {
                    Label("Stop", systemImage: "stop.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)
            }
        }
    }

    private func saveAndClose() {
        if let track = recorder.stop() {
            store.add(track)
        }
        dismiss()
    }

    private func discardAndClose() {
        _ = recorder.stop()
        dismiss()
    }
}
