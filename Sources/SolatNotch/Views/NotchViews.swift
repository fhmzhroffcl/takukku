import SwiftUI

struct CompactPrayerLeading: View {
    @ObservedObject var store: AppStore
    let onExpand: () -> Void
    let onHover: (Bool) -> Void
    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Group {
                if case .loaded(let schedule, let timeline) = store.state {
                    let sky = SkyState.resolve(now: context.date, schedule: schedule, timeline: timeline)
                    ZStack(alignment: .bottom) {
                        Circle().fill(LinearGradient(colors: compactColors(sky: sky), startPoint: .top, endPoint: .bottom))
                        Image(systemName: sky.phase.body == .sun ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                    }.frame(width: 22, height: 22)
                } else { Image(systemName: "moon.stars.fill").foregroundStyle(.secondary) }
            }.frame(width: 76, alignment: .trailing).overlay(alignment: .bottom) { CompactSkyRail(store: store, side: .leading) }.contentShape(Rectangle()).onTapGesture(perform: onExpand).onHover(perform: onHover)
        }
    }
    private func compactColors(sky: SkyState) -> [Color] { if UserDefaults.standard.string(forKey: "backgroundMode") == NotchBackgroundMode.weather.rawValue, let weather = store.weather { return weather.gradientColors.map(Color.init(hex:)) }; return Array(sky.phase.colors.suffix(2)) }
}

struct CompactPrayerTrailing: View {
    @ObservedObject var store: AppStore
    let onExpand: () -> Void
    let onHover: (Bool) -> Void
    @AppStorage("showCountdown") private var showCountdown = true
    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(spacing: 5) {
                if case .loaded(_, let timeline) = store.state {
                    Text(timeline.next.shortName).font(.caption2.weight(.bold)).foregroundStyle(.white)
                    Text(showCountdown ? CountdownFormatter.short(from: timeline.nextDate.timeIntervalSince(context.date)) : TimeFormatter.string(timeline.nextDate))
                        .font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.72))
                } else { Text("•••").font(.caption2).foregroundStyle(.secondary) }
            }.frame(width: 76, alignment: .leading).overlay(alignment: .bottom) { CompactSkyRail(store: store, side: .trailing) }.contentShape(Rectangle()).onTapGesture(perform: onExpand).onHover(perform: onHover)
        }
    }
}

struct ExpandedNotchView: View {
    @ObservedObject var store: AppStore
    let onCollapse: () -> Void
    let onHover: (Bool) -> Void
    var body: some View {
        Group {
            switch store.state {
            case .needsZone:
                NotchMessage(icon: "location", title: "Pilih zon waktu solat", buttonTitle: "Pilih Zon") { SettingsWindowPresenter.shared.show(store: store) }
            case .loading:
                NotchMessage(icon: "arrow.triangle.2.circlepath", title: "Mendapatkan waktu solat…", buttonTitle: nil, action: nil)
            case .failed(let reason):
                NotchMessage(icon: "wifi.exclamationmark", title: reason, buttonTitle: "Cuba Lagi") { store.refresh(force: true) }
            case .loaded(let schedule, let timeline):
                ScheduleNotchContent(schedule: schedule, timeline: timeline, weather: store.weather)
            }
        }
        .frame(width: 410, height: 194)
        .background(Color.black)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded(onCollapse))
        .onHover(perform: onHover)
        .preferredColorScheme(.dark)
    }
}

private struct ScheduleNotchContent: View {
    let schedule: DailyPrayerTimes
    let timeline: PrayerTimeline
    let weather: CurrentWeather?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("reducedAnimation") private var reducedAnimation = false
    @AppStorage("showWeather") private var showWeather = true
    @AppStorage("backgroundMode") private var backgroundMode = NotchBackgroundMode.prayer.rawValue
    @AppStorage("appearanceIntensity") private var intensity = 0.8
    @State private var animatedProgress = 0.0
    @State private var reveal = 0.0
    var body: some View {
        TimelineView(.periodic(from: .now, by: (systemReduceMotion || reducedAnimation) ? 60 : 15)) { context in
            let sky = SkyState.resolve(now: context.date, schedule: schedule, timeline: timeline)
            ZStack {
                LinearGradient(colors: backgroundColors(sky), startPoint: .top, endPoint: .bottom)
                    .opacity(intensity)
                    .animation(.easeInOut(duration: min(20, sky.phase.transitionDuration)), value: sky.phase)
                CelestialTimeline(celestialBody: sky.phase.body, progress: animatedProgress, stars: sky.phase.stars)
                VStack(spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(timeline.next.shortName).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.7))
                            Text(timeline.next.malayName).font(.title3.weight(.semibold))
                        }
                        Spacer()
                        if showWeather, let weather { Label("\(Int(weather.temperature.rounded()))°", systemImage: weather.symbol).font(.caption.weight(.medium)) }
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(TimeFormatter.string(timeline.nextDate)).font(.caption)
                            Text(CountdownFormatter.string(from: timeline.nextDate.timeIntervalSince(context.date))).font(.title3.monospacedDigit().weight(.medium))
                        }
                    }
                    Spacer(minLength: 22)
                    HStack(spacing: 3) {
                        ForEach(Prayer.allCases) { prayer in
                            if let time = schedule[prayer] {
                                VStack(spacing: 2) { Text(prayer.shortName).font(.system(size: 9, weight: prayer == timeline.next ? .bold : .medium)); Text(TimeFormatter.string(time)).font(.system(size: 10, design: .monospaced)) }
                                    .foregroundStyle(prayer == timeline.next ? .white : .white.opacity(0.64)).frame(maxWidth: .infinity)
                            }
                        }
                    }
                    HStack { Text(sourceText); Spacer(); Text(schedule.zoneCode) }.font(.system(size: 9)).foregroundStyle(.white.opacity(0.46))
                }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 10).opacity(0.72 + reveal * 0.28).offset(y: (1 - reveal) * -4)
            }.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onAppear { animatedProgress = 0; reveal = 0; withAnimation(.easeOut(duration: reducedAnimation || systemReduceMotion ? 0.01 : 0.72)) { animatedProgress = sky.progress; reveal = 1 } }
        }
    }
    private func backgroundColors(_ sky: SkyState) -> [Color] { backgroundMode == NotchBackgroundMode.weather.rawValue ? (weather?.gradientColors.map(Color.init(hex:)) ?? sky.phase.colors) : sky.phase.colors }
    private var sourceText: String { switch schedule.source { case .live: "JAKIM melalui Waktu Solat API"; case .cached: "Data tersimpan"; case .calculated: "Waktu anggaran" } }
}

private struct CompactSkyRail: View {
    enum Side { case leading, trailing }
    @ObservedObject var store: AppStore
    let side: Side
    @AppStorage("backgroundMode") private var backgroundMode = NotchBackgroundMode.prayer.rawValue
    @AppStorage("appearanceIntensity") private var intensity = 0.8
    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            if case .loaded(let schedule, let timeline) = store.state {
                let sky = SkyState.resolve(now: context.date, schedule: schedule, timeline: timeline)
                GeometryReader { proxy in
                    ZStack(alignment: side == .leading ? .trailing : .leading) {
                        Capsule().fill(LinearGradient(colors: colors(sky), startPoint: .leading, endPoint: .trailing)).opacity(0.78 * intensity).frame(height: 2)
                        Circle().fill(.white.opacity(0.9)).frame(width: 4, height: 4).offset(x: side == .leading ? -proxy.size.width * CGFloat(1 - sky.progress) : proxy.size.width * CGFloat(sky.progress - 1))
                    }
                }.frame(height: 4)
            }
        }.allowsHitTesting(false)
    }
    private func colors(_ sky: SkyState) -> [Color] { backgroundMode == NotchBackgroundMode.weather.rawValue ? (store.weather?.gradientColors.map(Color.init(hex:)) ?? sky.phase.colors) : sky.phase.colors }
}

private struct CelestialTimeline: View {
    let celestialBody: CelestialBody; let progress: Double; let stars: Double
    var body: some View {
        Canvas { context, size in
            let y: (Double) -> Double = { p in size.height * (0.68 - 0.35 * sin(.pi * p)) }
            var path = Path(); path.move(to: CGPoint(x: 24, y: y(0)))
            for step in 1...30 { let p = Double(step) / 30; path.addLine(to: CGPoint(x: 24 + (size.width - 48) * p, y: y(p))) }
            context.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 1)
            let p = min(1, max(0, progress)); let point = CGPoint(x: 24 + (size.width - 48) * p, y: y(p))
            context.fill(Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)), with: .color(celestialBody == .sun ? .yellow : .white.opacity(0.92)))
            if stars > 0 { for i in 0..<9 { let x = Double((i * 43) % Int(max(1, size.width))), yy = Double(24 + (i * 23) % 70); context.fill(Path(ellipseIn: CGRect(x: x, y: yy, width: 1.3, height: 1.3)), with: .color(.white.opacity(stars))) } }
        }.allowsHitTesting(false)
    }
}

private struct NotchMessage: View {
    let icon: String; let title: String; let buttonTitle: String?; let action: (() -> Void)?
    var body: some View {
        VStack(spacing: 10) { Image(systemName: icon).font(.title3); Text(title).font(.callout).foregroundStyle(.secondary); if let buttonTitle, let action { Button(buttonTitle, action: action).buttonStyle(.borderedProminent) } }
    }
}

enum TimeFormatter {
    static func string(_ date: Date) -> String { let f = DateFormatter(); f.timeZone = MalaysiaTime.zone; f.dateFormat = UserDefaults.standard.bool(forKey: "use24Hour") ? "HH:mm" : "h:mm a"; return f.string(from: date) }
}
enum CountdownFormatter {
    static func string(from interval: TimeInterval) -> String { let seconds = max(0, Int(interval)); return String(format: "%02d:%02d", seconds / 3600, (seconds % 3600) / 60) }
    static func short(from interval: TimeInterval) -> String { let minutes = max(0, Int(interval) / 60); return minutes >= 60 ? "\(minutes / 60)j \(minutes % 60)m" : "\(minutes)m" }
}
