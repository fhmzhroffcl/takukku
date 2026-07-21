import XCTest
@testable import SolatNotch

final class PrayerTimelineTests: XCTestCase {
    // TestFixture values are derived from the documented WLY01 response captured from
    // https://api.waktusolat.app/v2/solat/WLY01?year=2026&month=7 on 2026-07-10.
    func testTomorrowFajrBecomesNextAfterIsha() throws {
        let today = TestFixture.schedule(day: 10)
        let tomorrow = TestFixture.schedule(day: 11)
        let now = today[.isha]!.addingTimeInterval(60)
        let line = try PrayerTimelineEngine().timeline(now: now, today: today, tomorrow: tomorrow)
        XCTAssertEqual(line.next, .fajr); XCTAssertEqual(line.nextDate, tomorrow[.fajr])
    }
    func testBoundaryAtPrayerSelectsFollowingPrayer() throws {
        let today = TestFixture.schedule(day: 10), tomorrow = TestFixture.schedule(day: 11)
        let line = try PrayerTimelineEngine().timeline(now: today[.dhuhr]!, today: today, tomorrow: tomorrow)
        XCTAssertEqual(line.current, .dhuhr); XCTAssertEqual(line.next, .asr)
    }
    func testProgressIsBounded() throws {
        let today = TestFixture.schedule(day: 10), tomorrow = TestFixture.schedule(day: 11)
        let line = try PrayerTimelineEngine().timeline(now: today[.asr]!.addingTimeInterval(60), today: today, tomorrow: tomorrow)
        XCTAssertGreaterThanOrEqual(line.progress, 0); XCTAssertLessThanOrEqual(line.progress, 1)
    }
}

private enum TestFixture {
    static func schedule(day: Int) -> DailyPrayerTimes {
        let raw: [Int: [Prayer: TimeInterval]] = [
            10: [.fajr: 1783634220, .sunrise: 1783638540, .dhuhr: 1783660860, .asr: 1783673160, .maghrib: 1783683000, .isha: 1783687500],
            11: [.fajr: 1783720620, .sunrise: 1783724940, .dhuhr: 1783747320, .asr: 1783759560, .maghrib: 1783769400, .isha: 1783773900]
        ]
        let times = raw[day]!.mapValues(Date.init(timeIntervalSince1970:))
        return DailyPrayerTimes(date: MalaysiaTime.startOfDay(times[.fajr]!), zoneCode: "WLY01", zoneName: "Kuala Lumpur, Putrajaya", imsak: nil, times: times, source: .live, updatedAt: Date(timeIntervalSince1970: 1783634220))
    }
}
