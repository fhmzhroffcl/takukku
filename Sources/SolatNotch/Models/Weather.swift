import Foundation

struct CurrentWeather: Equatable {
    let temperature: Double
    let weatherCode: Int
    let updatedAt: Date
    var symbol: String {
        switch weatherCode {
        case 0: "sun.max.fill"
        case 1...3: "cloud.sun.fill"
        case 45...48: "cloud.fog.fill"
        case 51...67, 80...82: "cloud.rain.fill"
        case 71...77, 85...86: "cloud.snow.fill"
        case 95...99: "cloud.bolt.rain.fill"
        default: "cloud.fill"
        }
    }
    var gradientColors: [String] {
        switch weatherCode {
        case 0: ["59A5F5", "F6C75A"]
        case 1...3: ["4F6F91", "9BB3C9"]
        case 45...48: ["3C4652", "7D8791"]
        case 51...67, 80...82: ["21344D", "4D718E"]
        case 71...77, 85...86: ["71889D", "D6E5EF"]
        case 95...99: ["171D35", "5E4C78"]
        default: ["25364A", "62778A"]
        }
    }
}
