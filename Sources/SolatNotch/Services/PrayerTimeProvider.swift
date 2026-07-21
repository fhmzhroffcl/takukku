import Foundation

protocol PrayerTimeProvider {
    func prayerTimes(for date: Date, zone: MalaysiaPrayerZone) async throws -> DailyPrayerTimes
    func prayerTimes(from startDate: Date, to endDate: Date, zone: MalaysiaPrayerZone) async throws -> [DailyPrayerTimes]
}

enum PrayerProviderError: LocalizedError, Equatable {
    case invalidResponse(String), unavailable, missingCoordinates
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let reason): "Respons API tidak sah: \(reason)"
        case .unavailable: "Jadual untuk zon ini tidak tersedia"
        case .missingCoordinates: "Koordinat diperlukan untuk waktu anggaran"
        }
    }
}
