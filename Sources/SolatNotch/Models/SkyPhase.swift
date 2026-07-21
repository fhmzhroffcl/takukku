import SwiftUI

enum CelestialBody { case sun, moon }
enum SkyPhase: String, CaseIterable {
    case lateNight, preFajr, fajr, sunrise, morning, dhuhr, asr, goldenHour, maghrib, isha
    var colors: [Color] {
        switch self {
        case .lateNight: [.black, Color(red: 0.03, green: 0.05, blue: 0.14)]
        case .preFajr: [.black, Color(red: 0.13, green: 0.10, blue: 0.25)]
        case .fajr: [.black, Color(red: 0.35, green: 0.20, blue: 0.38), Color(red: 0.85, green: 0.45, blue: 0.32)]
        case .sunrise: [.black, Color(red: 0.95, green: 0.52, blue: 0.28), Color(red: 0.35, green: 0.58, blue: 0.78)]
        case .morning: [.black, Color(red: 0.18, green: 0.52, blue: 0.78)]
        case .dhuhr: [.black, Color(red: 0.10, green: 0.48, blue: 0.78)]
        case .asr: [.black, Color(red: 0.22, green: 0.46, blue: 0.68)]
        case .goldenHour: [.black, Color(red: 0.88, green: 0.43, blue: 0.20)]
        case .maghrib: [.black, Color(red: 0.55, green: 0.20, blue: 0.30), Color(red: 0.12, green: 0.08, blue: 0.20)]
        case .isha: [.black, Color(red: 0.04, green: 0.09, blue: 0.20)]
        }
    }
    var body: CelestialBody { [.lateNight, .preFajr, .maghrib, .isha].contains(self) ? .moon : .sun }
    var stars: Double { [.lateNight, .preFajr, .isha].contains(self) ? 0.7 : self == .maghrib ? 0.25 : 0 }
    var horizonIntensity: Double { [.fajr, .sunrise, .goldenHour, .maghrib].contains(self) ? 0.8 : 0.18 }
    var transitionDuration: Double { 90 }
}

struct SkyState {
    let phase: SkyPhase; let progress: Double
    static func resolve(now: Date, schedule: DailyPrayerTimes, timeline: PrayerTimeline) -> SkyState {
        guard let fajr = schedule[.fajr], let sunrise = schedule[.sunrise], let dhuhr = schedule[.dhuhr], let asr = schedule[.asr], let maghrib = schedule[.maghrib], let isha = schedule[.isha] else { return SkyState(phase: .lateNight, progress: 0) }
        let phase: SkyPhase
        if now < fajr.addingTimeInterval(-3600) { phase = .lateNight }
        else if now < fajr { phase = .preFajr }
        else if now < sunrise { phase = .fajr }
        else if now < sunrise.addingTimeInterval(2700) { phase = .sunrise }
        else if now < dhuhr { phase = .morning }
        else if now < asr { phase = .dhuhr }
        else if now < maghrib.addingTimeInterval(-3600) { phase = .asr }
        else if now < maghrib { phase = .goldenHour }
        else if now < isha { phase = .maghrib }
        else { phase = .isha }
        let length = timeline.intervalEnd.timeIntervalSince(timeline.intervalStart)
        return SkyState(phase: phase, progress: length > 0 ? min(1, max(0, now.timeIntervalSince(timeline.intervalStart) / length)) : 0)
    }
}
