import Foundation

struct ZoneCatalog {
    let zones: [MalaysiaPrayerZone]
    init(bundle: Bundle = .module) throws {
        let url = bundle.url(forResource: "malaysia_prayer_zones", withExtension: "json")!
        let raw = try JSONDecoder().decode([RawZone].self, from: Data(contentsOf: url))
        zones = raw.map {
            let districts = $0.daerah.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            return MalaysiaPrayerZone(code: $0.jakimCode, state: $0.negeri, name: $0.daerah, districts: districts)
        }.sorted { ($0.state, $0.code) < ($1.state, $1.code) }
    }
    func zone(code: String?) -> MalaysiaPrayerZone? { zones.first { $0.code == code } }
}
private struct RawZone: Decodable { let jakimCode, negeri, daerah: String }
