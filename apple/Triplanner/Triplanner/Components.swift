import SwiftUI

struct InfoCard: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.teal)
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
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
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
    var title: String
    var message: String
    var iconName: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .foregroundStyle(.teal)
                .frame(width: 42, height: 42)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

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
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .center)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }
}

extension View {
    func appPanel(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.quaternary)
            }
    }

    func readableWidth(_ width: CGFloat = 980) -> some View {
        self
            .frame(maxWidth: width, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
