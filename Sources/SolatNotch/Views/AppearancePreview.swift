import SwiftUI

struct AppearancePreview: View {
    let intensity: Double
    let backgroundMode: String
    let reducedAnimation: Bool
    @State private var phase = false
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sunrise.fill").foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 1) { Text("Pratonton").font(.caption2.weight(.bold)); Text("Gradient langsung").font(.caption2) }
            Spacer()
            Image(systemName: "cloud.sun.fill").foregroundStyle(.white)
            Text("27°").font(.caption2.monospacedDigit())
        }.padding(.horizontal, 14).background(LinearGradient(colors: backgroundMode == NotchBackgroundMode.weather.rawValue ? [Color(hex: "355C7D"), Color(hex: "C06C84")] : [Color(hex: "322659"), Color(hex: "C7A25A")], startPoint: phase ? .leading : .trailing, endPoint: phase ? .trailing : .leading).opacity(intensity), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.white).help("Pratonton langsung: perubahan warna dan keamatan akan kelihatan pada notch.")
        .onAppear { guard !reducedAnimation else { return }; withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { phase = true } }
    }
}
