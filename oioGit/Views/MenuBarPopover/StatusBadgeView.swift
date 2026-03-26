import SwiftUI

struct StatusBadgeView: View {
    let color: Color
    let size: CGFloat

    init(color: Color, size: CGFloat = 10) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .strokeBorder(.primary.opacity(0.15), lineWidth: 0.5)
            }
    }
}

#Preview {
    HStack(spacing: 12) {
        StatusBadgeView(color: StatusColor.clean)
        StatusBadgeView(color: StatusColor.modified)
        StatusBadgeView(color: StatusColor.conflict)
    }
    .padding()
}
