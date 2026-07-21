import SwiftUI

struct SettingsView: View {
    enum SettingsPane: String, CaseIterable, Identifiable { case location = "Lokasi", appearance = "Paparan", weather = "Cuaca", reminders = "Peringatan"; var id: String { rawValue } }
    @ObservedObject var store: AppStore
    @State private var section: SettingsPane = .location
    @State private var search = ""
    @State private var selectedState = "Semua negeri"
    @AppStorage("expansionMode") private var expansionMode = ExpansionMode.both.rawValue
    @AppStorage("asrMethod") private var asrMethod = AsrMethod.shafii.rawValue
    @AppStorage("language") private var language = AppLanguage.ms.rawValue
    @AppStorage("use24Hour") private var use24Hour = true
    @AppStorage("showSunrise") private var showSunrise = true
    @AppStorage("showCountdown") private var showCountdown = true
    @AppStorage("showWeather") private var showWeather = true
    @AppStorage("backgroundMode") private var backgroundMode = NotchBackgroundMode.prayer.rawValue
    @AppStorage("reducedAnimation") private var reducedAnimation = false
    @AppStorage("appearanceIntensity") private var intensity = 0.8
    @AppStorage("calculatedFallbackEnabled") private var fallbackEnabled = false
    @AppStorage("liveLocation") private var liveLocation = false
    @AppStorage("notificationSound") private var notificationSound = NotificationSoundChoice.device.rawValue

    private var filtered: [MalaysiaPrayerZone] {
        store.catalog.zones.filter { (selectedState == "Semua negeri" || $0.state == selectedState) && (search.isEmpty || "\($0.code) \($0.name) \($0.districts.joined(separator: " "))".localizedCaseInsensitiveContains(search)) }
    }
    private var states: [String] { ["Semua negeri"] + Array(Set(store.catalog.zones.map(\.state))).sorted() }
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) { ForEach(SettingsPane.allCases) { Text($0.rawValue).tag($0) } }
                .pickerStyle(.segmented).labelsHidden().frame(width: 390).padding(14)
            Divider()
            Group { switch section { case .location: locationPane; case .appearance: appearancePane; case .weather: weatherPane; case .reminders: remindersPane } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(minWidth: 680, minHeight: 570).background(.regularMaterial)
    }

    private var locationPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Cari negeri, daerah atau kod zon", text: $search).textFieldStyle(.roundedBorder)
                Button("Guna Lokasi Saya") { store.locationManager.requestSuggestion(catalog: store.catalog) }
            }
            HStack {
                Picker("Negeri", selection: $selectedState) { ForEach(states, id: \.self) { Text($0).tag($0) } }.frame(width: 230)
                Toggle("Lokasi langsung", isOn: Binding(get: { liveLocation }, set: { liveLocation = $0; if $0 { store.startLiveLocation() } else { store.locationManager.stopLiveLocation() } })).help("Kemas kini cadangan zon dan cuaca apabila Mac bergerak.")
                if store.locationManager.authorizationStatus == .denied { Label("Kebenaran lokasi ditolak", systemImage: "location.slash").foregroundStyle(.orange).font(.caption) }
            }
            if let suggested = store.locationManager.suggestedZone {
                HStack { Label("Cadangan: \(suggested.code) · \(suggested.state)", systemImage: "location.fill"); Spacer(); Button("Sahkan Zon") { store.select(suggested) } }.padding(10).background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            List(filtered, selection: Binding(get: { store.selectedZone?.code }, set: { code in if let zone = store.catalog.zone(code: code) { store.select(zone) } })) { zone in
                VStack(alignment: .leading, spacing: 2) { Text("\(zone.code) · \(zone.state)").fontWeight(.medium); Text(zone.name).font(.caption).foregroundStyle(.secondary).lineLimit(2) }.padding(.vertical, 3).tag(zone.code)
            }.listStyle(.inset)
            HStack { if let selected = store.selectedZone { Label("Zon dipilih: \(selected.code)", systemImage: "checkmark.circle.fill").foregroundStyle(.green) } else { Label("Pilih satu zon untuk mula", systemImage: "exclamationmark.circle").foregroundStyle(.orange) }; Spacer(); Text("60 zon JAKIM") }
                .font(.caption).foregroundStyle(.secondary)
        }.padding(18)
    }

    private var appearancePane: some View {
        ScrollView {
            Form {
                Section("Waktu Solat") {
                    Picker("Kaedah Asar", selection: $asrMethod) { Text("Syafie").tag(AsrMethod.shafii.rawValue); Text("Hanafi").tag(AsrMethod.hanafi.rawValue) }
                    Picker("Bahasa", selection: $language) { Text("Bahasa Melayu").tag("ms"); Text("English").tag("en") }
                    Toggle("Format 24 jam", isOn: $use24Hour)
                    Toggle("Tunjuk Syuruk", isOn: $showSunrise)
                    Toggle("Benarkan waktu anggaran jika data rasmi tiada", isOn: $fallbackEnabled)
                }
                Section("Takuk") {
                    Picker("Kembangkan melalui", selection: $expansionMode) { Text("Hover").tag("hover"); Text("Klik").tag("click"); Text("Kedua-duanya").tag("both"); Text("Jangan automatik").tag("never") }
                    Toggle("Tunjuk kira detik", isOn: $showCountdown)
                    Toggle("Tunjuk cuaca semasa", isOn: $showWeather)
                    Picker("Warna latar", selection: $backgroundMode) { Text("Ikut waktu solat").tag(NotchBackgroundMode.prayer.rawValue); Text("Ikut cuaca").tag(NotchBackgroundMode.weather.rawValue) }
                    Toggle("Kurangkan animasi", isOn: $reducedAnimation)
                    LabeledContent("Keamatan warna") { Slider(value: $intensity, in: 0.25...1).frame(width: 220).help("Mengawal kepekatan gradient pada notch dan rail bawah.") }
                    AppearancePreview(intensity: intensity, backgroundMode: backgroundMode, reducedAnimation: reducedAnimation).frame(height: 48)
                }
                Section("Pelarasan minit") {
                    ForEach(Prayer.allCases) { prayer in
                        VStack(alignment: .leading, spacing: 2) { LabeledContent(prayer.malayName) { Text("\(adjustment(prayer)) min").monospacedDigit() }; Slider(value: adjustmentDoubleBinding(prayer), in: -30...30, step: 1).help("Tambah atau tolak minit daripada jadual rasmi zon ini.") }
                    }
                }
            }.formStyle(.grouped).padding(14)
        }
    }

    private var weatherPane: some View {
        Form {
            Section("Paparan Cuaca") {
                Toggle("Tunjuk suhu dan ikon cuaca", isOn: $showWeather)
                Picker("Warna notch", selection: $backgroundMode) { Text("Ikut waktu solat").tag(NotchBackgroundMode.prayer.rawValue); Text("Ikut keadaan cuaca").tag(NotchBackgroundMode.weather.rawValue) }
                if let weather = store.weather {
                    LabeledContent("Sekarang") { Label("\(Int(weather.temperature.rounded()))°C", systemImage: weather.symbol) }
                    LabeledContent("Dikemas kini") { Text(TimeFormatter.string(weather.updatedAt)) }
                    Button("Kemas Kini Cuaca") { store.refreshWeather() }
                } else {
                    Label("Benarkan lokasi untuk memaparkan cuaca semasa.", systemImage: "location.slash").foregroundStyle(.secondary)
                    Button("Benarkan Lokasi") { store.locationManager.requestSuggestion(catalog: store.catalog) }
                }
            }
            Section { Text("Cuaca menggunakan Open-Meteo dan koordinat kekal pada Mac ini. Waktu solat rasmi tetap berdasarkan zon JAKIM yang disahkan.").font(.caption).foregroundStyle(.secondary) }
        }.formStyle(.grouped).padding(14)
    }

    private var remindersPane: some View {
        ScrollView {
            Form {
                Section { Text("Pilih peringatan berasingan untuk setiap waktu. Focus dan Jangan Ganggu macOS tetap mengawal bila notifikasi dipaparkan.").font(.caption).foregroundStyle(.secondary) }
                Section("macOS") {
                    Button("Benarkan Pemberitahuan") { Task { _ = try? await NotificationScheduler().requestAuthorization() } }
                    Button("Hantar Pemberitahuan Ujian") { Task { if (try? await NotificationScheduler().requestAuthorization()) == true { try? await NotificationScheduler().sendTestNotification() } } }
                    Picker("Bunyi", selection: $notificationSound) { Text("Bunyi peranti").tag(NotificationSoundChoice.device.rawValue); Text("Senyap").tag(NotificationSoundChoice.silent.rawValue); Text("Azan (adhan.caf)").tag(NotificationSoundChoice.azan.rawValue) }
                    Text("Untuk Azan, letakkan fail adhan.caf dalam bundle aplikasi. Jika tiada, macOS tidak memainkan bunyi tersuai.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Peringatan Solat") {
                    ForEach(Prayer.allCases) { prayer in
                        HStack { Toggle(prayer.malayName, isOn: notificationBinding(prayer)); Spacer(); Picker("Masa", selection: leadBinding(prayer)) { Text("Tepat waktu").tag(0); Text("5 min awal").tag(5); Text("10 min awal").tag(10); Text("15 min awal").tag(15); Text("30 min awal").tag(30) }.labelsHidden().frame(width: 150) }
                    }
                }
            }.formStyle(.grouped).padding(14)
        }
    }

    private func adjustment(_ prayer: Prayer) -> Int { UserDefaults.standard.integer(forKey: "adjust.\(prayer.rawValue)") }
    private func adjustmentBinding(_ prayer: Prayer) -> Binding<Int> { Binding(get: { adjustment(prayer) }, set: { UserDefaults.standard.set($0, forKey: "adjust.\(prayer.rawValue)") }) }
    private func adjustmentDoubleBinding(_ prayer: Prayer) -> Binding<Double> { Binding(get: { Double(adjustment(prayer)) }, set: { UserDefaults.standard.set(Int($0.rounded()), forKey: "adjust.\(prayer.rawValue)") }) }
    private func notificationBinding(_ prayer: Prayer) -> Binding<Bool> { Binding(get: { UserDefaults.standard.bool(forKey: "notify.\(prayer.rawValue).enabled") }, set: { UserDefaults.standard.set($0, forKey: "notify.\(prayer.rawValue).enabled"); store.rescheduleNotifications(); if $0 { Task { _ = try? await NotificationScheduler().requestAuthorization() } } }) }
    private func leadBinding(_ prayer: Prayer) -> Binding<Int> { Binding(get: { UserDefaults.standard.integer(forKey: "notify.\(prayer.rawValue).lead") }, set: { UserDefaults.standard.set($0, forKey: "notify.\(prayer.rawValue).lead"); store.rescheduleNotifications() }) }
}
