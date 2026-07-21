import Foundation

enum WidgetSnapshotWriter {
    static func write(schedule: DailyPrayerTimes, weather: CurrentWeather?) {
        let payload: [String: Any] = [
            "zone": schedule.zoneCode,
            "date": MalaysiaTime.dateKey(schedule.date),
            "times": Dictionary(uniqueKeysWithValues: schedule.times.map { ($0.key.rawValue, $0.value.timeIntervalSince1970) }),
            "temperature": weather?.temperature as Any,
            "weatherCode": weather?.weatherCode as Any,
            "updatedAt": Date().timeIntervalSince1970
        ]
        UserDefaults(suiteName: "group.my.takukku")?.set(payload, forKey: "widget.snapshot")
    }
}
