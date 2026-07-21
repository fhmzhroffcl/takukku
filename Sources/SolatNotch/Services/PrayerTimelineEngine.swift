import Foundation

struct PrayerTimelineEngine {
    func timeline(now: Date, today: DailyPrayerTimes, tomorrow: DailyPrayerTimes?) throws -> PrayerTimeline {
        let events = Prayer.allCases.compactMap { prayer in today[prayer].map { (prayer, $0) } }
        guard events.count == Prayer.allCases.count else { throw PrayerProviderError.invalidResponse("waktu wajib tidak lengkap") }
        if let next = events.first(where: { $0.1 > now }) {
            let index = events.firstIndex(where: { $0.0 == next.0 })!
            let previous = index > 0 ? events[index - 1] : (Prayer.isha, MalaysiaTime.calendar.date(byAdding: .day, value: -1, to: events.last!.1)!)
            return PrayerTimeline(current: index > 0 ? previous.0 : nil, next: next.0, nextDate: next.1, intervalStart: previous.1, intervalEnd: next.1)
        }
        guard let fajr = tomorrow?[.fajr] else { throw PrayerProviderError.unavailable }
        return PrayerTimeline(current: .isha, next: .fajr, nextDate: fajr, intervalStart: events.last!.1, intervalEnd: fajr)
    }
}
