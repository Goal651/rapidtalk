import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.l) {
                    // Header
                    Text("Profile")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, AppTheme.Spacing.xxl)
                        .padding(.horizontal, AppTheme.Spacing.l)

                    if vm.isLoading {
                        LoadingView(message: "Loading profile...", style: .pulse)
                            .padding(.top, AppTheme.Spacing.xxl)
                    } else if let err = vm.errorMessage {
                        ErrorStateView(message: err)
                            .padding(.top, AppTheme.Spacing.xxl)
                    } else if let user = vm.user {
                        VStack(spacing: AppTheme.Spacing.l) {
                            // Profile Header Card
                            ProfileHeaderCard(user: user, onEditTap: {
                                showEditProfile = true
                            })
                            .padding(.horizontal, AppTheme.Spacing.l)
                            
                            // Stats Section
                            ProfileStatsSection()
                                .padding(.horizontal, AppTheme.Spacing.l)
                            
                            // Settings Sections
                            VStack(spacing: AppTheme.Spacing.m) {
                                ProfileSectionHeader(title: "Account")
                                    .padding(.horizontal, AppTheme.Spacing.l)
                                
                                VStack(spacing: 0) {
                                    ProfileMenuItem(
                                        icon: "person.circle",
                                        title: "Edit Profile",
                                        subtitle: "Update your information",
                                        action: { showEditProfile = true }
                                    )
                                    
                                    ProfileMenuDivider()
                                    
                                    ProfileMenuItem(
                                        icon: "bell.badge",
                                        title: "Notifications",
                                        subtitle: "Manage notification settings",
                                        action: { }
                                    )
                                    
                                    ProfileMenuDivider()
                                    
                                    ProfileMenuItem(
                                        icon: "lock.shield",
                                        title: "Privacy & Security",
                                        subtitle: "Control your privacy",
                                        action: { }
                                    )
                                }
                                .background(AppTheme.SurfaceColors.surfaceLight)
                                .cornerRadius(AppTheme.CornerRadius.l)
                                .padding(.horizontal, AppTheme.Spacing.l)
                            }
                            
                            // Preferences Section
                            VStack(spacing: AppTheme.Spacing.m) {
                                ProfileSectionHeader(title: "Preferences")
                                    .padding(.horizontal, AppTheme.Spacing.l)
                                
                                VStack(spacing: 0) {
                                    ProfileMenuItem(
                                        icon: "paintbrush",
                                        title: "Appearance",
                                        subtitle: "Theme and display options",
                                        action: { }
                                    )
                                    
                                    ProfileMenuDivider()
                                    
                                    ProfileMenuItem(
                                        icon: "globe",
                                        title: "Language",
                                        subtitle: "English",
                                        action: { }
                                    )
                                }
                                .background(AppTheme.SurfaceColors.surfaceLight)
                                .cornerRadius(AppTheme.CornerRadius.l)
                                .padding(.horizontal, AppTheme.Spacing.l)
                            }
                            
                            // About Section
                            VStack(spacing: AppTheme.Spacing.m) {
                                ProfileSectionHeader(title: "About")
                                    .padding(.horizontal, AppTheme.Spacing.l)
                                
                                VStack(spacing: 0) {
                                    ProfileMenuItem(
                                        icon: "info.circle",
                                        title: "Help & Support",
                                        subtitle: "Get help with VynqTalk",
                                        action: { }
                                    )
                                    
                                    ProfileMenuDivider()
                                    
                                    ProfileMenuItem(
                                        icon: "doc.text",
                                        title: "Terms & Privacy",
                                        subtitle: "Legal information",
                                        action: { }
                                    )
                                    
                                    ProfileMenuDivider()
                                    
                                    ProfileMenuItem(
                                        icon: "star",
                                        title: "Rate VynqTalk",
                                        subtitle: "Share your feedback",
                                        action: { }
                                    )
                                }
                                .background(AppTheme.SurfaceColors.surfaceLight)
                                .cornerRadius(AppTheme.CornerRadius.l)
                                .padding(.horizontal, AppTheme.Spacing.l)
                            }
                            
                            // Logout Button
                            CustomButton(
                                title: "Logout",
                                style: .secondary,
                                action: {
                                    nav.showAlert(AlertConfig(
                                        title: "Logout",
                                        message: "Are you sure you want to logout?",
                                        primaryButton: .init(
                                            title: "Logout",
                                            style: .destructive,
                                            action: { authVM.logout() }
                                        ),
                                        secondaryButton: .init(
                                            title: "Cancel",
                                            style: .cancel,
                                            action: {}
                                        )
                                    ))
                                },
                                accessibilityLabel: "Logout",
                                accessibilityHint: "Shows confirmation dialog before logging out"
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                                    .stroke(AppTheme.AccentColors.error.opacity(0.6), lineWidth: 2)
                            )
                            .padding(.horizontal, AppTheme.Spacing.l)
                            .padding(.top, AppTheme.Spacing.m)
                            
                            // App Version
                            Text("VynqTalk v1.0.0")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.TextColors.tertiary)
                                .padding(.top, AppTheme.Spacing.s)
                                .padding(.bottom, AppTheme.Spacing.xxl)
                        }
                    } else {
                        EmptyProfileStateView()
                            .padding(.top, AppTheme.Spacing.xxl)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: AppTheme.AnimationDuration.normal)) {
                appeared = true
            }
        }
        .task { await vm.loadMe() }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: vm.user)
        }
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    let user: User
    let onEditTap: () -> Void
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            // Avatar with edit button
            ZStack(alignment: .bottomTrailing) {
                avatar
                    .frame(width: 100, height: 100)
                
                Button(action: onEditTap) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.AccentColors.primary)
                        .background(
                            Circle()
                                .fill(AppTheme.GradientColors.deepBlack)
                                .frame(width: 28, height: 28)
                        )
                }
                .offset(x: 5, y: 5)
            }
            .scaleEffect(appeared ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)
            
            // User Info
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(user.name ?? "Unknown User")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.TextColors.primary)
                
                if let email = user.email {
                    Text(email)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.TextColors.secondary)
                }
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.TextColors.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, AppTheme.Spacing.xs)
                }
                
                // Online Status Badge
                HStack(spacing: AppTheme.Spacing.xs) {
                    Circle()
                        .fill(user.online == true ? AppTheme.AccentColors.online : AppTheme.TextColors.tertiary)
                        .frame(width: 8, height: 8)
                    
                    Text(user.online == true ? "Online" : "Offline")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.TextColors.secondary)
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(AppTheme.SurfaceColors.surface)
                .cornerRadius(AppTheme.CornerRadius.m)
                .padding(.top, AppTheme.Spacing.s)
            }
        }
        .padding(AppTheme.Spacing.l)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                .fill(AppTheme.SurfaceColors.surfaceLight)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.AccentColors.primary.opacity(0.3),
                                    AppTheme.AccentColors.secondary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: AppTheme.AccentColors.primary.opacity(0.1), radius: 20, y: 10)
        .onAppear {
            appeared = true
        }
    }
    
    @ViewBuilder
    private var avatar: some View {
        if let avatarString = user.avatar,
           let url = URL(string: avatarString),
           avatarString.lowercased().hasPrefix("http") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                case .failure:
                    defaultAvatar
                @unknown default:
                    defaultAvatar
                }
            }
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            )
        } else {
            defaultAvatar
        }
    }
    
    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.AccentColors.primary.opacity(0.3),
                            AppTheme.AccentColors.secondary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.TextColors.primary)
        }
        .frame(width: 100, height: 100)
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}

// MARK: - Profile Stats Section

struct ProfileStatsSection: View {
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            StatCard(icon: "message.fill", value: "127", label: "Messages")
            StatCard(icon: "person.2.fill", value: "45", label: "Contacts")
            StatCard(icon: "photo.fill", value: "89", label: "Media")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.AccentColors.primary)
            
            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.TextColors.primary)
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.m)
        .background(AppTheme.SurfaceColors.surfaceLight)
        .cornerRadius(AppTheme.CornerRadius.m)
    }
}

// MARK: - Profile Section Header

struct ProfileSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.TextColors.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Profile Menu Item

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.AccentColors.primary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.AccentColors.primary.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
            .padding(AppTheme.Spacing.m)
            .background(isPressed ? AppTheme.SurfaceColors.surface : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct ProfileMenuDivider: View {
    var body: some View {
        Divider()
            .background(AppTheme.TextColors.tertiary.opacity(0.3))
            .padding(.leading, 60)
    }
}

// MARK: - Empty State View

struct EmptyProfileStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.TextColors.tertiary)
            
            Text("Profile Not Found")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.TextColors.primary)
            
            Text("Unable to load your profile")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.TextColors.secondary)
        }
    }
}

struct ErrorStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.AccentColors.error)
            
            Text("Error")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.TextColors.primary)
            
            Text(message)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.TextColors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.l)
        }
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    let user: User?
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var status: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.l) {
                        CustomTextField(
                            label: "Name",
                            placeholder: "Enter your name",
                            text: $name
                        )
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("Bio")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.TextColors.secondary)
                            
                            TextEditor(text: $bio)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.TextColors.primary)
                                .frame(height: 100)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.SurfaceColors.surface)
                                .cornerRadius(AppTheme.CornerRadius.m)
                        }
                        
                        CustomTextField(
                            label: "Status",
                            placeholder: "What's on your mind?",
                            text: $status
                        )
                        
                        CustomButton(
                            title: "Save Changes",
                            style: .primary,
                            action: {
                                dismiss()
                            }
                        )
                        .padding(.top, AppTheme.Spacing.m)
                    }
                    .padding(AppTheme.Spacing.l)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.TextColors.primary)
                }
            }
        }
        .onAppear {
            name = user?.name ?? ""
            bio = user?.bio ?? ""
            status = user?.status ?? ""
        }
    }
}


