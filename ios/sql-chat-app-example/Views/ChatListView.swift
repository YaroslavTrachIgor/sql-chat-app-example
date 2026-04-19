import SwiftUI

func avatarCircle(_ initials: String, size: CGFloat) -> some View {
    ZStack {
        Circle()
            .fill(Color(.tertiarySystemFill))
            .frame(width: size, height: size)
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(.primary)
    }
}
