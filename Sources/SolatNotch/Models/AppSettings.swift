import Foundation

enum ExpansionMode: String, CaseIterable, Identifiable { case hover, click, both, never; var id: String { rawValue } }
enum AsrMethod: String, CaseIterable, Identifiable { case shafii, hanafi; var id: String { rawValue } }
enum AppLanguage: String, CaseIterable, Identifiable { case ms, en; var id: String { rawValue } }
enum NotchBackgroundMode: String, CaseIterable, Identifiable { case prayer, weather; var id: String { rawValue } }
enum NotificationSoundChoice: String, CaseIterable, Identifiable { case device, silent, azan; var id: String { rawValue } }

struct NotificationPreference: Codable, Equatable {
    var enabled = false
    var leadMinutes = 0
}
