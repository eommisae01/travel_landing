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

    var moodLine: String {
        switch self {
        case .setouchi: return "청량하고 여행 앱다운 기본 테마"
        case .sunrise: return "밥집, 산책, 쇼핑이 많은 여행에 어울려요"
        case .forest: return "자연, 숙소, 느린 일정 중심일 때 차분해요"
        case .graphite: return "정보 밀도가 높은 도시 이동형 여행에 좋아요"
        }
    }

    var accent: Color {
        switch self {
        case .setouchi: return Color(red: 0.04, green: 0.55, blue: 0.58)
        case .sunrise: return Color(red: 0.82, green: 0.28, blue: 0.20)
        case .forest: return Color(red: 0.10, green: 0.42, blue: 0.34)
        case .graphite: return Color(red: 0.22, green: 0.25, blue: 0.34)
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .setouchi: return Color(red: 0.42, green: 0.58, blue: 0.72)
        case .sunrise: return Color(red: 0.68, green: 0.18, blue: 0.30)
        case .forest: return Color(red: 0.55, green: 0.63, blue: 0.25)
        case .graphite: return Color(red: 0.52, green: 0.45, blue: 0.61)
        }
    }

    var warmAccent: Color {
        switch self {
        case .setouchi: return Color(red: 0.88, green: 0.68, blue: 0.20)
        case .sunrise: return Color(red: 0.91, green: 0.59, blue: 0.20)
        case .forest: return Color(red: 0.75, green: 0.55, blue: 0.32)
        case .graphite: return Color(red: 0.62, green: 0.58, blue: 0.54)
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
                .font(.subheadline.weight(.black))
                .foregroundStyle(theme.accent)
            Text(subtitle.isEmpty ? "입력 전" : subtitle)
                .font(.headline.weight(.semibold))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.primary.opacity(0.055))
        }
    }
}

struct ScreenHeader: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent)
                .frame(width: 4, height: subtitle.isEmpty ? 34 : 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 1)
    }
}

struct SectionLabel: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.black))
            .tracking(0.2)
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
                    .font(.headline.weight(.black))
                Text(message)
                    .font(.callout.weight(.semibold))
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
                .stroke(Color.primary.opacity(0.055))
        }
    }
}

extension View {
    func appPanel(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(17)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.055))
            }
            .shadow(color: Color.primary.opacity(0.022), radius: 7, x: 0, y: 3)
    }

    func appScreenBackground() -> some View {
        modifier(AppScreenBackgroundModifier())
    }

    func readableWidth(_ width: CGFloat = 1080) -> some View {
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
                Color.secondary.opacity(0.032)
                    .ignoresSafeArea()
            }
            .tint(theme.accent)
    }
}
