import SwiftUI
import WidgetKit

struct TakukkuWidgetEntry: TimelineEntry { let date: Date; let snapshot: WidgetSnapshot? }
struct WidgetSnapshot {
    let zone: String; let times: [String: Date]; let temperature: Double?; let weatherCode: Int?
    static func load() -> WidgetSnapshot? {
        guard let values = UserDefaults(suiteName: "group.my.takukku")?.dictionary(forKey: "widget.snapshot"), let zone = values["zone"] as? String, let rawTimes = values["times"] as? [String: Double] else { return nil }
        return WidgetSnapshot(zone: zone, times: rawTimes.mapValues(Date.init(timeIntervalSince1970:)), temperature: values["temperature"] as? Double, weatherCode: values["weatherCode"] as? Int)
    }
}

struct TakukkuWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TakukkuWidgetEntry { TakukkuWidgetEntry(date: .now, snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (TakukkuWidgetEntry) -> Void) { completion(TakukkuWidgetEntry(date: .now, snapshot: .load())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TakukkuWidgetEntry>) -> Void) {
        let entry = TakukkuWidgetEntry(date: .now, snapshot: .load())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900))))
    }
}

struct TakukkuWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TakukkuWidgetEntry
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo.opacity(0.7)], startPoint: .top, endPoint: .bottom)
            if let snapshot = entry.snapshot { content(snapshot) } else { Text("Buka Solat Notch untuk memilih zon").font(.caption).multilineTextAlignment(.center).padding() }
        }.containerBackground(.black, for: .widget)
    }
    @ViewBuilder private func content(_ snapshot: WidgetSnapshot) -> some View {
        switch family {
        case .systemSmall: VStack(alignment: .leading) { Label(snapshot.zone, systemImage: "location.fill").font(.caption2); Text("Waktu solat").font(.headline); Text(Self.time(snapshot.times["fajr"])).font(.title3.monospacedDigit()) }
        case .systemMedium: HStack { VStack(alignment: .leading) { Text(snapshot.zone).font(.caption); Text("Waktu solat hari ini").font(.headline); Text("Subuh  \(Self.time(snapshot.times["fajr"]))").font(.caption.monospacedDigit()) }; Spacer(); weather(snapshot) }
        default: VStack(alignment: .leading, spacing: 8) { HStack { Text("Solat hari ini").font(.title3.weight(.semibold)); Spacer(); weather(snapshot) }; Text(snapshot.zone).font(.caption); HStack { timeCell("SUB", snapshot.times["fajr"]); timeCell("SYR", snapshot.times["sunrise"]); timeCell("ZHR", snapshot.times["dhuhr"]); timeCell("ASR", snapshot.times["asr"]); timeCell("MGR", snapshot.times["maghrib"]); timeCell("ISY", snapshot.times["isha"]) } }
        }
    }
    private func timeCell(_ label: String, _ date: Date?) -> some View { VStack(alignment: .leading) { Text(label).font(.caption2.bold()); Text(Self.time(date)).font(.caption.monospacedDigit()) } }
    @ViewBuilder private func weather(_ snapshot: WidgetSnapshot) -> some View { if let temperature = snapshot.temperature { Label("\(Int(temperature.rounded()))°", systemImage: "cloud.sun.fill").font(.caption) } }
    private static func time(_ date: Date?) -> String { guard let date else { return "—" }; let f = DateFormatter(); f.timeZone = TimeZone(identifier: "Asia/Kuala_Lumpur"); f.dateFormat = "HH:mm"; return f.string(from: date) }
}

struct TakukkuWidget: Widget {
    let kind = "TakukkuWidget"
    var body: some WidgetConfiguration { StaticConfiguration(kind: kind, provider: TakukkuWidgetProvider()) { TakukkuWidgetView(entry: $0) }.configurationDisplayName("Solat Notch").description("Waktu solat dan cuaca semasa.").supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]) }
}

@main struct TakukkuWidgetBundle: WidgetBundle { var body: some Widget { TakukkuWidget() } }
