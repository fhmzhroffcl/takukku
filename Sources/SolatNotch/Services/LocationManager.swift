import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var suggestedZone: MalaysiaPrayerZone?
    @Published private(set) var latestLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var onLocationUpdate: (() -> Void)?
    private let manager = CLLocationManager()
    private var catalog: ZoneCatalog?

    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyKilometer; manager.distanceFilter = 1000; manager.pausesLocationUpdatesAutomatically = true; authorizationStatus = manager.authorizationStatus }
    func requestSuggestion(catalog: ZoneCatalog) { self.catalog = catalog; manager.requestAlwaysAuthorization(); manager.requestLocation(); if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorized { manager.startUpdatingLocation() } }
    func startLiveLocation(catalog: ZoneCatalog) { self.catalog = catalog; manager.requestAlwaysAuthorization(); if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorized { manager.startUpdatingLocation() } }
    func stopLiveLocation() { manager.stopUpdatingLocation() }
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.authorizationStatus = status
            if status == .authorizedAlways || status == .authorized { self?.manager.startUpdatingLocation() }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            latestLocation = location
            onLocationUpdate?()
            if let mark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
                let text = [mark.administrativeArea, mark.subAdministrativeArea, mark.locality, mark.subLocality].compactMap { $0 }.joined(separator: " ").lowercased()
                suggestedZone = catalog?.zones.first { zone in zone.state.lowercased().split(separator: " ").contains(where: { text.contains($0) }) && zone.districts.contains(where: { text.contains($0.lowercased()) }) }
            }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
