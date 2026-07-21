import Adhan
import Foundation

struct CalculationLocation: Codable { let latitude: Double; let longitude: Double }

struct CalculatedPrayerTimeProvider: PrayerTimeProvider {
    let location: CalculationLocation?
    let asrMethod: AsrMethod
    let adjustments: [Prayer: Int]

    func prayerTimes(for date: Date, zone: MalaysiaPrayerZone) async throws -> DailyPrayerTimes {
        guard let location else { throw PrayerProviderError.missingCoordinates }
        var parameters = CalculationMethod.singapore.params
        parameters.madhab = asrMethod == .hanafi ? .hanafi : .shafi
        let components = MalaysiaTime.calendar.dateComponents([.year, .month, .day], from: date)
        guard let calculated = PrayerTimes(coordinates: Coordinates(latitude: location.latitude, longitude: location.longitude), date: components, calculationParameters: parameters) else { throw PrayerProviderError.unavailable }
        let base: [Prayer: Date] = [.fajr: calculated.fajr, .sunrise: calculated.sunrise, .dhuhr: calculated.dhuhr, .asr: calculated.asr, .maghrib: calculated.maghrib, .isha: calculated.isha]
        let adjusted = Dictionary(uniqueKeysWithValues: base.map { prayer, value in
            (prayer, value.addingTimeInterval(TimeInterval(60 * (adjustments[prayer] ?? 0))))
        })
        return DailyPrayerTimes(date: MalaysiaTime.startOfDay(date), zoneCode: zone.code, zoneName: zone.name, imsak: nil, times: adjusted, source: .calculated, updatedAt: Date())
    }
    func prayerTimes(from startDate: Date, to endDate: Date, zone: MalaysiaPrayerZone) async throws -> [DailyPrayerTimes] {
        var result: [DailyPrayerTimes] = [], cursor = MalaysiaTime.startOfDay(startDate)
        while cursor <= MalaysiaTime.startOfDay(endDate) { result.append(try await prayerTimes(for: cursor, zone: zone)); cursor = MalaysiaTime.calendar.date(byAdding: .day, value: 1, to: cursor)! }
        return result
    }
}
