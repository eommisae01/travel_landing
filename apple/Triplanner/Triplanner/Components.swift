import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case setouchi
    case sunrise
    case forest
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .setouchi: return "Seaside"
        case .sunrise: return "Cherry"
        case .forest: return "Olive"
        case .graphite: return "Graphite"
        }
    }

    var subtitle: String {
        switch self {
        case .setouchi: return "바다, 미술관, 여유"
        case .sunrise: return "체리 레드와 민트"
        case .forest: return "올리브와 조용한 숙소"
        case .graphite: return "차분한 도시 이동"
        }
    }

    var moodLine: String {
        switch self {
        case .setouchi: return "밝고 부드러운 바닷가 여행 톤"
        case .sunrise: return "식당, 카페, 사진 자료가 많은 여행에 좋아요"
        case .forest: return "숙소와 자연 중심의 느린 여행에 어울려요"
        case .graphite: return "일정과 이동 정보가 많은 도시 여행에 좋아요"
        }
    }

    var accent: Color {
        switch self {
        case .setouchi: return Color(red: 0.05, green: 0.58, blue: 0.55)
        case .sunrise: return Color(red: 0.72, green: 0.08, blue: 0.15)
        case .forest: return Color(red: 0.10, green: 0.31, blue: 0.25)
        case .graphite: return Color(red: 0.18, green: 0.20, blue: 0.28)
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .setouchi: return Color(red: 0.58, green: 0.72, blue: 0.74)
        case .sunrise: return Color(red: 0.53, green: 0.75, blue: 0.69)
        case .forest: return Color(red: 0.63, green: 0.65, blue: 0.28)
        case .graphite: return Color(red: 0.63, green: 0.57, blue: 0.69)
        }
    }

    var warmAccent: Color {
        switch self {
        case .setouchi: return Color(red: 0.88, green: 0.78, blue: 0.22)
        case .sunrise: return Color(red: 0.88, green: 0.86, blue: 0.22)
        case .forest: return Color(red: 0.73, green: 0.50, blue: 0.27)
        case .graphite: return Color(red: 0.78, green: 0.62, blue: 0.32)
        }
    }

    static var stored: AppTheme {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? AppTheme.setouchi.rawValue
        return AppTheme(rawValue: rawValue) ?? .setouchi
    }

    static let storageKey = "triplanner.theme"
}

enum AppDisplaySize: String, CaseIterable, Identifiable {
    case standard
    case comfortable
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .comfortable: return "Comfort"
        case .large: return "Large"
        }
    }

    var subtitle: String {
        switch self {
        case .standard: return "정보를 더 많이 보기"
        case .comfortable: return "기본 추천 크기"
        case .large: return "아이패드/부모님 보기 좋게"
        }
    }

    var scale: CGFloat {
        switch self {
        case .standard: return 0.66
        case .comfortable: return 0.70
        case .large: return 0.74
        }
    }

    func size(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    static let storageKey = "triplanner.display-size"
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.setouchi
}

private struct AppDisplaySizeKey: EnvironmentKey {
    static let defaultValue = AppDisplaySize.comfortable
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }

    var appDisplaySize: AppDisplaySize {
        get { self[AppDisplaySizeKey.self] }
        set { self[AppDisplaySizeKey.self] = newValue }
    }
}

struct InfoCard: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.appDisplaySize) private var displaySize
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: displaySize.size(18), weight: .black, design: .rounded))
                .foregroundStyle(theme.accent)
            Text(subtitle.isEmpty ? "입력 전" : subtitle)
                .font(.system(size: displaySize.size(22), weight: .semibold, design: .rounded))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: displaySize.size(88), alignment: .topLeading)
        .padding(17)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.primary.opacity(0.055))
        }
    }
}

struct ScreenHeader: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.appDisplaySize) private var displaySize
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent)
                .frame(width: 5, height: displaySize.size(subtitle.isEmpty ? 38 : 50))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: displaySize.size(28), weight: .black, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: displaySize.size(15), weight: .semibold, design: .rounded))
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
    @Environment(\.appDisplaySize) private var displaySize
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: displaySize.size(18), weight: .black, design: .rounded))
            .tracking(0.2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.appDisplaySize) private var displaySize
    var title: String
    var message: String
    var iconName: String

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            Image(systemName: iconName)
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(width: 44, height: 44)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: displaySize.size(22), weight: .black, design: .rounded))
                Text(message)
                    .font(.system(size: displaySize.size(18), weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .center)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.055))
        }
    }
}

extension View {
    func appPanel(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.065))
            }
            .shadow(color: Color.primary.opacity(0.026), radius: 9, x: 0, y: 4)
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
                Color.secondary.opacity(0.026)
                    .ignoresSafeArea()
            }
            .tint(theme.accent)
    }
}
