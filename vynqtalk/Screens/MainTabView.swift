import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @State private var appeared: Bool = false
    @State private var selectedTab: Int = 0
    @State private var isAdmin: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Chats - responsive for iPad
            ResponsiveHomeScreen()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .font(.system(size: 24, weight: selectedTab == 0 ? .semibold : .regular))
                        Text("Chats")
                            .font(AppTheme.Typography.caption2)
                    }
                }
                .tag(0)
            
            // Admin tab (only visible for admins)
            if isAdmin {
                NavigationStack {
                    AdminDashboard()
                }
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 1 ? "shield.fill" : "shield")
                            .font(.system(size: 24, weight: selectedTab == 1 ? .semibold : .regular))
                        Text("Admin")
                            .font(AppTheme.Typography.caption2)
                    }
                }
                .tag(1)
            }

            ProfileScreen()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == (isAdmin ? 2 : 1) ? "person.crop.circle.fill" : "person.crop.circle")
                            .font(.system(size: 24, weight: selectedTab == (isAdmin ? 2 : 1) ? .semibold : .regular))
                        Text("Profile")
                            .font(AppTheme.Typography.caption2)
                    }
                }
                .tag(isAdmin ? 2 : 1)
        }
        .accentColor(AppTheme.AccentColors.primary)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            
            // Background with blur effect - Deep black
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(
                red: 0.03, green: 0.04, blue: 0.08, alpha: 0.95
            )
            
            // Add subtle blue top border
            appearance.shadowColor = UIColor(
                red: 0.20, green: 0.60, blue: 1.0, alpha: 0.2
            )
            
            // Selected item color (electric blue)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(
                red: 0.20, green: 0.60, blue: 1.0, alpha: 1.0
            )
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.20, green: 0.60, blue: 1.0, alpha: 1.0),
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
            
            // Check if user is admin
            await checkAdminStatus()
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
    
    // MARK: - Check Admin Status
    
    @MainActor
    private func checkAdminStatus() async {
        // Check if user has admin role stored
        if let userRole = UserDefaults.standard.string(forKey: "user_role"),
           userRole == "ADMIN" {
            isAdmin = true
            return
        }
        
        // Fetch user profile to check role
        do {
            let response: APIResponse<User> = try await APIClient.shared.get("/users/me")
            if response.success, let user = response.data {
                isAdmin = user.userRole == .admin
                
                // Store for future use
                if let role = user.userRole {
                    UserDefaults.standard.set(role.rawValue, forKey: "user_role")
                }
            }
        } catch {
            #if DEBUG
            print("❌ Failed to check admin status: \(error)")
            #endif
        }
    }
}

