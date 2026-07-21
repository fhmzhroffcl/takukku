import Foundation

struct MalaysiaLivePrayerTimeProvider: PrayerTimeProvider {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.waktusolat.app")!
    init(session: URLSession = .shared) { self.session = session }

    func prayerTimes(for date: Date, zone: MalaysiaPrayerZone) async throws -> DailyPrayerTimes {
        let all = try await fetchMonth(containing: date, zone: zone)
        guard let day = all.first(where: { MalaysiaTime.calendar.isDate($0.date, inSameDayAs: date) }) else { throw PrayerProviderError.unavailable }
        return day
    }

    func prayerTimes(from startDate: Date, to endDate: Date, zone: MalaysiaPrayerZone) async throws -> [DailyPrayerTimes] {
        var cursor = MalaysiaTime.startOfDay(startDate), result: [DailyPrayerTimes] = []
        var fetched = Set<String>()
        while cursor <= endDate {
            let comps = MalaysiaTime.calendar.dateComponents([.year, .month], from: cursor)
            let key = "\(comps.year!)-\(comps.month!)"
            if fetched.insert(key).inserted { result += try await fetchMonth(containing: cursor, zone: zone) }
            cursor = MalaysiaTime.calendar.date(byAdding: .month, value: 1, to: cursor)!
        }
        return result.filter { $0.date >= MalaysiaTime.startOfDay(startDate) && $0.date <= endDate }
    }

    private func fetchMonth(containing date: Date, zone: MalaysiaPrayerZone) async throws -> [DailyPrayerTimes] {
        let c = MalaysiaTime.calendar.dateComponents([.year, .month], from: date)
        var parts = URLComponents(url: baseURL.appending(path: "v2/solat/\(zone.code)"), resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "year", value: String(c.year!)), URLQueryItem(name: "month", value: String(c.month!))]
        var request = URLRequest(url: parts.url!); request.setValue("application/json", forHTTPHeaderField: "Accept"); request.timeoutInterval = 15
        #if DEBUG
        print("[PrayerAPI] GET /v2/solat/\(zone.code)?year=\(c.year!)&month=\(c.month!)")
        #endif
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw PrayerProviderError.unavailable }
        guard !data.isEmpty, !String(decoding: data.prefix(32), as: UTF8.self).lowercased().contains("<html") else { throw PrayerProviderError.invalidResponse("respons kosong atau HTML") }
        let payload = try JSONDecoder().decode(APIResponse.self, from: data)
        guard payload.zone == zone.code, payload.year == c.year, payload.monthNumber == c.month else { throw PrayerProviderError.invalidResponse("zon atau bulan tidak sepadan") }
        let mapped = try payload.prayers.map { try map($0, payload: payload, zone: zone) }
        guard !mapped.isEmpty else { throw PrayerProviderError.invalidResponse("tiada jadual") }
        return mapped
    }

    private func map(_ day: APIPrayerDay, payload: APIResponse, zone: MalaysiaPrayerZone) throws -> DailyPrayerTimes {
        let pairs: [(Prayer, Int64)] = [(.fajr, day.fajr), (.sunrise, day.syuruk), (.dhuhr, day.dhuhr), (.asr, day.asr), (.maghrib, day.maghrib), (.isha, day.isha)]
        let dates = pairs.map { ($0.0, Date(timeIntervalSince1970: TimeInterval($0.1))) }
        guard dates.allSatisfy({ MalaysiaTime.calendar.component(.day, from: $0.1) == day.day }),
              zip(dates, dates.dropFirst()).allSatisfy({ $0.0.1 < $0.1.1 }) else { throw PrayerProviderError.invalidResponse("masa tidak munasabah") }
        return DailyPrayerTimes(date: MalaysiaTime.startOfDay(dates[0].1), zoneCode: zone.code, zoneName: zone.name,
            imsak: day.imsak.map { Date(timeIntervalSince1970: TimeInterval($0)) }, times: Dictionary(uniqueKeysWithValues: dates),
            source: .live, updatedAt: Date())
    }
}

private struct APIResponse: Decodable {
    let zone: String; let year: Int; let monthNumber: Int; let prayers: [APIPrayerDay]
    enum CodingKeys: String, CodingKey { case zone, year, monthNumber = "month_number", prayers }
}
private struct APIPrayerDay: Decodable {
    let day: Int; let imsak: Int64?; let fajr, syuruk, dhuhr, asr, maghrib, isha: Int64
}
