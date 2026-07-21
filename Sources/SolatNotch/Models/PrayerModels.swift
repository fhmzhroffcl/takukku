import Foundation

enum Prayer: String, Codable, CaseIterable, Identifiable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha
    var id: String { rawValue }
    var malayName: String {
        switch self { case .fajr: "Subuh"; case .sunrise: "Syuruk"; case .dhuhr: "Zohor"; case .asr: "Asar"; case .maghrib: "Maghrib"; case .isha: "Isyak" }
    }
    var shortName: String {
        switch self { case .fajr: "SUB"; case .sunrise: "SYR"; case .dhuhr: "ZHR"; case .asr: "ASR"; case .maghrib: "MGR"; case .isha: "ISY" }
    }
}

struct MalaysiaPrayerZone: Identifiable, Codable, Hashable {
    let id: String
    let code: String
    let state: String
    let name: String
    let districts: [String]

    init(code: String, state: String, name: String, districts: [String]) {
        self.id = code; self.code = code; self.state = state; self.name = name; self.districts = districts
    }
}

enum ScheduleSource: String, Codable { case live, cached, calculated }

struct DailyPrayerTimes: Identifiable, Codable, Equatable {
    var id: String { "\(zoneCode)-\(Self.dayKey(date))" }
    let date: Date
    let zoneCode: String
    let zoneName: String?
    let imsak: Date?
    let times: [Prayer: Date]
    var source: ScheduleSource
    var updatedAt: Date

    subscript(_ prayer: Prayer) -> Date? { times[prayer] }
    static func dayKey(_ date: Date) -> String { MalaysiaTime.dateKey(date) }
}

struct PrayerTimeline: Equatable {
    let current: Prayer?
    let next: Prayer
    let nextDate: Date
    let intervalStart: Date
    let intervalEnd: Date
    var progress: Double {
        let length = intervalEnd.timeIntervalSince(intervalStart)
        guard length > 0 else { return 0 }
        return min(1, max(0, Date().timeIntervalSince(intervalStart) / length))
    }
}

enum PrayerDataState: Equatable {
    case needsZone, loading, loaded(DailyPrayerTimes, PrayerTimeline), failed(String)
}

enum MalaysiaTime {
    static let zone = TimeZone(identifier: "Asia/Kuala_Lumpur")!
    static var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = zone; return c }
    static func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }
    static func dateKey(_ date: Date) -> String {
        let f = DateFormatter(); f.calendar = calendar; f.timeZone = zone; f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
}
