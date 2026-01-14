import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                Text("Profile")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.TextColors.primary)
                    .padding(.top, AppTheme.Spacing.xxl)

                if vm.isLoading {
                    ProgressView()
                        .tint(AppTheme.TextColors.primary)
                } else if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(AppTheme.AccentColors.error)
                        .font(AppTheme.Typography.body)
                } else if let user = vm.user {
                    UserComponent(user: user)

                    Divider()
                        .overlay(AppTheme.TextColors.tertiary)

                    Button {
                        APIClient.shared.logout()
                        authVM.loggedIn = false
                        authVM.authToken = ""
                        authVM.userId = 0
                        nav.reset(to: .welcome)
                    } label: {
                        Text("Logout")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.TextColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.AccentColors.error)
                            .cornerRadius(AppTheme.CornerRadius.l)
                    }
                    .padding(.top, AppTheme.Spacing.s)
                } else {
                    Text("No profile loaded")
                        .foregroundColor(AppTheme.TextColors.secondary)
                        .font(AppTheme.Typography.body)
                }

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.l)
        }
        .navigationBarBackButtonHidden()
        .task { await vm.loadMe() }
    }
}


