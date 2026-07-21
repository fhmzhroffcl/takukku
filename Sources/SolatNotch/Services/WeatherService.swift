import CoreLocation
import Foundation

struct WeatherService {
    func current(at coordinate: CLLocationCoordinate2D) async throws -> CurrentWeather {
        var parts = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        parts.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "timezone", value: "Asia/Kuala_Lumpur")
        ]
        let (data, response) = try await URLSession.shared.data(from: parts.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
        let payload = try JSONDecoder().decode(Response.self, from: data)
        return CurrentWeather(temperature: payload.current.temperature, weatherCode: payload.current.weatherCode, updatedAt: Date())
    }
}
private struct Response: Decodable {
    let current: Current
    struct Current: Decodable {
        let temperature: Double; let weatherCode: Int
        enum CodingKeys: String, CodingKey { case temperature = "temperature_2m", weatherCode = "weather_code" }
    }
}
