import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @State private var appeared: Bool = false
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .font(.system(size: 24, weight: selectedTab == 0 ? .semibold : .regular))
                        Text("Chats")
                            .font(AppTheme.Typography.caption2)
                    }
                }
                .tag(0)

            ProfileScreen()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 1 ? "person.crop.circle.fill" : "person.crop.circle")
                            .font(.system(size: 24, weight: selectedTab == 1 ? .semibold : .regular))
                        Text("Profile")
                            .font(AppTheme.Typography.caption2)
                    }
                }
                .tag(1)
        }
        .accentColor(AppTheme.AccentColors.primary)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            
            // Background with blur effect
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(
                red: 0.08, green: 0.05, blue: 0.15, alpha: 0.95
            )
            
            // Add subtle top border
            appearance.shadowColor = UIColor(
                red: 0.55, green: 0.45, blue: 1.0, alpha: 0.2
            )
            
            // Selected item color (vibrant purple)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(
                red: 0.55, green: 0.45, blue: 1.0, alpha: 1.0
            )
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.55, green: 0.45, blue: 1.0, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
            
            // Normal item color (white with opacity)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .font: UIFont.systemFont(ofSize: 11, weight: .regular)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .task {
            if !wsM.isConnected {
                wsM.connect()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: AppTheme.AnimationDuration.slow)) {
                appeared = true
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }
}


