import SwiftUI

struct CustomBackButton: View {
    @EnvironmentObject var nav: NavigationCoordinator
    let title: String?
    let action: (() -> Void)?
    
    init(title: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if let action = action {
                action()
            } else {
                nav.pop()
            }
        }) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                
                if let title = title {
                    Text(title)
                        .font(AppTheme.Typography.body)
                }
            }
            .foregroundColor(AppTheme.AccentColors.primary)
        }
        .accessibilityLabel("Back")
        .accessibilityHint("Returns to the previous screen")
    }
}
