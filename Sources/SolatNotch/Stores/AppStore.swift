import AppKit
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var state: PrayerDataState = .needsZone
    @Published var selectedZone: MalaysiaPrayerZone?
    @Published var isExpanded = false
    @Published var lastSchedule: DailyPrayerTimes?
    @Published private(set) var weather: CurrentWeather?
    let catalog: ZoneCatalog
    let locationManager = LocationManager()
    private let live = MalaysiaLivePrayerTimeProvider()
    private let cache = ScheduleCache()
    private let timeline = PrayerTimelineEngine()
    private var refreshTask: Task<Void, Never>?

    init() {
        catalog = (try? ZoneCatalog()) ?? ZoneCatalog.empty
        selectedZone = catalog.zone(code: UserDefaults.standard.string(forKey: "selectedZoneCode"))
        state = selectedZone == nil ? .needsZone : .loading
        locationManager.onLocationUpdate = { [weak self] in self?.refreshWeather() }
        observeLifecycle()
    }

    func start() { if selectedZone != nil { refresh() } }
    func startLiveLocation() { locationManager.startLiveLocation(catalog: catalog) }
    func select(_ zone: MalaysiaPrayerZone) {
        selectedZone = zone; UserDefaults.standard.set(zone.code, forKey: "selectedZoneCode"); refresh(force: true)
    }
    func refresh(force: Bool = false) {
        guard let zone = selectedZone else { state = .needsZone; return }
        refreshTask?.cancel(); state = .loading
        refreshTask = Task {
            let now = Date(), tomorrowDate = MalaysiaTime.calendar.date(byAdding: .day, value: 1, to: now)!
            if !force, let cachedToday = await cache.load(date: now, zone: zone), let cachedTomorrow = await cache.load(date: tomorrowDate, zone: zone), let line = try? timeline.timeline(now: now, today: cachedToday, tomorrow: cachedTomorrow) {
                lastSchedule = cachedToday; state = .loaded(cachedToday, line); WidgetSnapshotWriter.write(schedule: cachedToday, weather: weather)
            }
            do {
                let monthEnd = MalaysiaTime.calendar.dateInterval(of: .month, for: now)!.end.addingTimeInterval(-1)
                let schedules = try await live.prayerTimes(from: now, to: monthEnd, zone: zone)
                try await cache.save(schedules)
                guard let today = schedules.first(where: { MalaysiaTime.calendar.isDate($0.date, inSameDayAs: now) }) else { throw PrayerProviderError.unavailable }
                var tomorrow = schedules.first(where: { MalaysiaTime.calendar.isDate($0.date, inSameDayAs: tomorrowDate) })
                if tomorrow == nil { tomorrow = try? await live.prayerTimes(for: tomorrowDate, zone: zone) }
                let line = try timeline.timeline(now: now, today: today, tomorrow: tomorrow)
                lastSchedule = today; state = .loaded(today, line)
                WidgetSnapshotWriter.write(schedule: today, weather: weather)
                await NotificationScheduler().schedule([today] + (tomorrow.map { [$0] } ?? []), preferences: Self.notificationPreferences())
            } catch {
                if case .loaded = state { return }
                if UserDefaults.standard.bool(forKey: "calculatedFallbackEnabled"), let coordinate = locationManager.latestLocation?.coordinate {
                    let provider = CalculatedPrayerTimeProvider(location: CalculationLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), asrMethod: UserDefaults.standard.string(forKey: "asrMethod") == AsrMethod.hanafi.rawValue ? .hanafi : .shafii, adjustments: Self.adjustments())
                    if let today = try? await provider.prayerTimes(for: now, zone: zone), let tomorrow = try? await provider.prayerTimes(for: tomorrowDate, zone: zone), let line = try? timeline.timeline(now: now, today: today, tomorrow: tomorrow) { lastSchedule = today; state = .loaded(today, line); return }
                }
                state = .failed(error.localizedDescription)
            }
        }
    }
    func recalculate() {
        guard let zone = selectedZone, let today = lastSchedule else { return }
        Task { if let tomorrow = await cache.load(date: MalaysiaTime.calendar.date(byAdding: .day, value: 1, to: Date())!, zone: zone), let line = try? timeline.timeline(now: Date(), today: today, tomorrow: tomorrow) { state = .loaded(today, line) } }
    }
    func refreshWeather() {
        guard let coordinate = locationManager.latestLocation?.coordinate else { return }
        Task { weather = try? await WeatherService().current(at: coordinate) }
    }
    func rescheduleNotifications() {
        guard let today = lastSchedule, let zone = selectedZone else { return }
        Task {
            let tomorrowDate = MalaysiaTime.calendar.date(byAdding: .day, value: 1, to: Date())!
            let tomorrow = await cache.load(date: tomorrowDate, zone: zone)
            await NotificationScheduler().schedule([today] + (tomorrow.map { [$0] } ?? []), preferences: Self.notificationPreferences())
        }
    }
    private func observeLifecycle() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in }
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.refresh() } }
    }
    private static func notificationPreferences() -> [Prayer: NotificationPreference] { Dictionary(uniqueKeysWithValues: Prayer.allCases.map { prayer in (prayer, NotificationPreference(enabled: UserDefaults.standard.bool(forKey: "notify.\(prayer.rawValue).enabled"), leadMinutes: UserDefaults.standard.integer(forKey: "notify.\(prayer.rawValue).lead"))) }) }
    private static func adjustments() -> [Prayer: Int] { Dictionary(uniqueKeysWithValues: Prayer.allCases.map { ($0, UserDefaults.standard.integer(forKey: "adjust.\($0.rawValue)")) }) }
}

private extension ZoneCatalog { static var empty: ZoneCatalog { try! ZoneCatalog(bundle: .module) } }
