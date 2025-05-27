import SwiftUI

// TopRoundedRectangle shape definition remains the same...
struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: Angle(degrees: 270), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct BottomControlsContainerView<NotificationContent: View, MainContent: View>: View {
    let notificationContent: NotificationContent
    let mainContent: MainContent
    var mainBackgroundColor: Color = Color.gray.opacity(0.2)
    var notificationBackgroundColor: Color = Color.blue.opacity(0.3) // Contrasting color
    var cornerRadius: CGFloat = 20

    init(
        mainBackgroundColor: Color = Color.gray.opacity(0.2),
        notificationBackgroundColor: Color = Color.blue.opacity(0.3),
        cornerRadius: CGFloat = 20,
        @ViewBuilder notificationContent: () -> NotificationContent,
        @ViewBuilder mainContent: () -> MainContent
    ) {
        self.mainBackgroundColor = mainBackgroundColor
        self.notificationBackgroundColor = notificationBackgroundColor
        self.cornerRadius = cornerRadius
        self.notificationContent = notificationContent()
        self.mainContent = mainContent()
    }

    var body: some View {
        VStack(spacing: 0) {
            notificationContent
                .padding(.horizontal, 8) // Add some horizontal padding for the notification content
                .padding(.vertical, 4)   // Add some vertical padding
                .background(notificationBackgroundColor) // Apply the contrasting background to the notification area
                // This notification area will implicitly be at the top due to VStack ordering.

            mainContent
                // Add padding for mainContent if needed, e.g., .padding(.top, 8) if spacing is desired
        }
        // The .padding(.top, cornerRadius / 2) might need adjustment or be removed
        // if the notification area itself provides enough visual spacing from the top curve.
        // Let's remove it for now and see the effect.
        // .padding(.top, cornerRadius / 2) 
        .background(
            TopRoundedRectangle(radius: cornerRadius)
                .fill(mainBackgroundColor) // Main background for the whole container
        )
    }
}
