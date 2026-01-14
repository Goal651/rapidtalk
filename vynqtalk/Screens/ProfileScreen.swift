import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var appeared = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            if vm.isLoading {
                PremiumLoadingView()
            } else if let err = vm.errorMessage {
                PremiumErrorView(message: err)
            } else if let user = vm.user {
                ScrollView {
                    VStack(spacing: 32) {
                        // Clean Profile Header
                        CleanProfileHeader(
                            user: user,
                            onEditTap: { showEditProfile = true },
                            onImageTap: { showImagePicker = true }
                        )
                        .padding(.top, 40)
                        
                        // Essential Content Only
                        EssentialProfileContent(user: user)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            } else {
                PremiumEmptyStateView()
            }
        }
        .navigationBarBackButtonHidden()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .task { await vm.loadMe() }
        .sheet(isPresented: $showEditProfile) {
            PremiumEditProfileSheet(user: vm.user)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

// MARK: - Clean Profile Header

struct CleanProfileHeader: View {
    let user: User
    let onEditTap: () -> Void
    let onImageTap: () -> Void
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Simple Avatar
            Button(action: onImageTap) {
                ZStack {
                    // Avatar
                    Group {
                        if let avatarString = user.avatar,
                           let url = URL(string: avatarString),
                           avatarString.lowercased().hasPrefix("http") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    defaultAvatarContent
                                }
                            }
                        } else {
                            defaultAvatarContent
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppTheme.AccentColors.primary,
                                        AppTheme.AccentColors.secondary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    
                    // Edit indicator
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(AppTheme.AccentColors.primary)
                        )
                        .offset(x: 32, y: 32)
                }
            }
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
            
            // User Info
            VStack(spacing: 12) {
                Text(user.name ?? "Unknown User")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if let bio = user.bio {
                    Text(bio)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Status Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(user.online == true ? AppTheme.AccentColors.online : .gray)
                        .frame(width: 8, height: 8)
                    
                    Text(user.online == true ? "Online" : "Offline")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.1))
                )
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            
            // Edit Button
            Button(action: onEditTap) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Edit Profile")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.1))
                )
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
    
    private var defaultAvatarContent: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary,
                    AppTheme.AccentColors.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Essential Profile Content

struct EssentialProfileContent: View {
    let user: User
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var authVM: AuthViewModel
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Account Settings
            SettingsSection(
                title: "Account",
                items: [
                    SettingsItem(icon: "person.circle", title: "Personal Info", subtitle: "Update your details", action: {}),
                    SettingsItem(icon: "bell.badge", title: "Notifications", subtitle: "Manage alerts", action: {}),
                    SettingsItem(icon: "lock.shield", title: "Privacy & Security", subtitle: "Control your privacy", action: {})
                ]
            )
            
            // App Settings
            SettingsSection(
                title: "Preferences",
                items: [
                    SettingsItem(icon: "paintbrush", title: "Appearance", subtitle: "Themes & display", action: {}),
                    SettingsItem(icon: "questionmark.circle", title: "Help & Support", subtitle: "Get assistance", action: {})
                ]
            )
            
            // Logout Button
            Button {
                nav.showAlert(AlertConfig(
                    title: "Sign Out",
                    message: "Are you sure you want to sign out?",
                    primaryButton: .init(
                        title: "Sign Out",
                        style: .destructive,
                        action: { authVM.logout() }
                    ),
                    secondaryButton: .init(
                        title: "Cancel",
                        style: .cancel,
                        action: {}
                    )
                ))
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(AppTheme.AccentColors.error)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(AppTheme.AccentColors.error.opacity(0.3), lineWidth: 1.5)
                        )
                )
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Settings Section

struct SettingsSection: View {
    let title: String
    let items: [SettingsItem]
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    SettingsRow(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .background(.white.opacity(0.1))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct SettingsItem {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
}

struct SettingsRow: View {
    let item: SettingsItem
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            item.action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.AccentColors.primary)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(item.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(18)
            .background(isPressed ? .white.opacity(0.05) : .clear)
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

// MARK: - Supporting Views

struct PremiumLoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
            }
            
            Text("Loading your profile...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

struct PremiumErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(AppTheme.AccentColors.error)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

struct PremiumEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Profile Not Found")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Unable to load your profile information")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Premium Edit Profile Sheet

struct PremiumEditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    let user: User?
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var status: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ModernTextField(
                            label: "Name",
                            placeholder: "Enter your name",
                            text: $name,
                            icon: "person.fill"
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bio")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextEditor(text: $bio)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(height: 100)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("Save Changes")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(26)
                        }
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
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

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
