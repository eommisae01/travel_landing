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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 30, weight: .black, design: .rounded))
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

extension View {
    func appPanel(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    func readableWidth(_ width: CGFloat = 980) -> some View {
        self
            .frame(maxWidth: width, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
