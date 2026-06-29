import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case setouchi
    case sunrise
    case forest
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .setouchi: return "Setouchi"
        case .sunrise: return "Sunrise"
        case .forest: return "Forest"
        case .graphite: return "Graphite"
        }
    }

    var subtitle: String {
        switch self {
        case .setouchi: return "바다와 미술관"
        case .sunrise: return "따뜻한 도시 산책"
        case .forest: return "조용한 자연 여행"
        case .graphite: return "차분한 출장/도시"
        }
    }

    var accent: Color {
        switch self {
        case .setouchi: return .teal
        case .sunrise: return .orange
        case .forest: return .green
        case .graphite: return .indigo
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .setouchi: return .blue
        case .sunrise: return .pink
        case .forest: return .mint
        case .graphite: return .purple
        }
    }

    var warmAccent: Color {
        switch self {
        case .setouchi: return .orange
        case .sunrise: return .yellow
        case .forest: return .cyan
        case .graphite: return .gray
        }
    }

    static var stored: AppTheme {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? AppTheme.setouchi.rawValue
        return AppTheme(rawValue: rawValue) ?? .setouchi
    }

    static let storageKey = "triplanner.theme"
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.setouchi
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

struct InfoCard: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
            Text(subtitle.isEmpty ? "입력 전" : subtitle)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
    }
}

struct ScreenHeader: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.accent)
                .frame(width: 5, height: subtitle.isEmpty ? 34 : 52)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }
}

struct SectionLabel: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var message: String
    var iconName: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(width: 36, height: 36)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.black))
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }
}

extension View {
    func appPanel(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.quaternary)
            }
            .shadow(color: Color.primary.opacity(0.035), radius: 8, x: 0, y: 4)
    }

    func appScreenBackground() -> some View {
        modifier(AppScreenBackgroundModifier())
    }

    func readableWidth(_ width: CGFloat = 980) -> some View {
        self
            .frame(maxWidth: width, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
    }
}

private struct AppScreenBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Color.secondary.opacity(0.028)
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.055),
                            theme.warmAccent.opacity(0.025),
                            Color.secondary.opacity(0.026)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .ignoresSafeArea()
            }
            .tint(theme.accent)
    }
}
