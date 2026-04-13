import SwiftUI

// Shared avatar helper used across views

func avatarCircle(_ initials: String, size: CGFloat) -> some View {
    ZStack {
        Circle()
            .fill(Color(red: 0.06, green: 0.2, blue: 0.37))
            .frame(width: size, height: size)
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(Color.accentColor)
    }
}
