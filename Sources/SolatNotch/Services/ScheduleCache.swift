import Foundation

actor ScheduleCache {
    private let directory: URL
    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appending(path: "Takukku/Schedules", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    func load(date: Date, zone: MalaysiaPrayerZone) -> DailyPrayerTimes? {
        let url = directory.appending(path: "\(zone.code)-\(MalaysiaTime.dateKey(date)).json")
        guard let data = try? Data(contentsOf: url), var value = try? JSONDecoder().decode(DailyPrayerTimes.self, from: data), value.zoneCode == zone.code else { return nil }
        value.source = .cached; return value
    }
    func save(_ schedules: [DailyPrayerTimes]) throws {
        let encoder = JSONEncoder()
        for schedule in schedules {
            let url = directory.appending(path: "\(schedule.zoneCode)-\(MalaysiaTime.dateKey(schedule.date)).json")
            try encoder.encode(schedule).write(to: url, options: .atomic)
        }
    }
}

struct CachedMalaysiaPrayerTimeProvider: PrayerTimeProvider {
    let cache: ScheduleCache
    func prayerTimes(for date: Date, zone: MalaysiaPrayerZone) async throws -> DailyPrayerTimes {
        guard let value = await cache.load(date: date, zone: zone) else { throw PrayerProviderError.unavailable }; return value
    }
    func prayerTimes(from startDate: Date, to endDate: Date, zone: MalaysiaPrayerZone) async throws -> [DailyPrayerTimes] {
        var result: [DailyPrayerTimes] = [], cursor = MalaysiaTime.startOfDay(startDate)
        while cursor <= toEndDate(to: endDate) { if let v = await cache.load(date: cursor, zone: zone) { result.append(v) }; cursor = MalaysiaTime.calendar.date(byAdding: .day, value: 1, to: cursor)! }
        return result
    }
    private func toEndDate(to date: Date) -> Date { MalaysiaTime.startOfDay(date) }
}
