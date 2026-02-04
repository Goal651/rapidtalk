//
//  AdminUserDetails.swift
//  vynqtalk
//
//  Admin user details and actions
//

import SwiftUI

struct AdminUserDetails: View {
    @Environment(\.dismiss) var dismiss
    let user: AdminUser
    @StateObject private var adminVM = AdminViewModel()
    @StateObject private var adminWS = AdminWSManager()
    @State private var showSuspendConfirmation = false
    @State private var suspendReason = ""
    @State private var isProcessing = false
    
    private var avatarURL: URL? {
        guard let avatar = user.avatar else { return nil }
        
        if avatar.lowercased().hasPrefix("http") {
            return URL(string: avatar)
        }
        
        let baseURL = APIClient.environment.baseURL
        let cleanPath = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        return URL(string: "\(baseURL)\(cleanPath)")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.GradientColors.deepBlack
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Avatar and basic info
                        userHeaderSection
                        
                        // Stats
                        userStatsSection
                        
                        // Account info
                        accountInfoSection
                        
                        // Actions
                        actionsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: adminWS.messageUpdate) { _, update in
                if let update = update {
                    print("First it was workinig \(update)")
                    adminVM.handleMessageUpdate(update)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.AccentColors.primary)
                }
            }
            .alert("Suspend User", isPresented: $showSuspendConfirmation) {
                TextField("Reason (optional)", text: $suspendReason)
                Button("Cancel", role: .cancel) {}
                Button(user.status == "suspended" ? "Unsuspend" : "Suspend", role: .destructive) {
                    Task {
                        await handleSuspendAction()
                    }
                }
            } message: {
                Text(user.status == "suspended" 
                    ? "Are you sure you want to unsuspend this user?" 
                    : "Are you sure you want to suspend this user? They will not be able to use the app.")
            }
        }
    }
    
    // MARK: - User Header
    
    private var userHeaderSection: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let url = avatarURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        default:
                            defaultAvatar
                        }
                    }
                } else {
                    defaultAvatar
                }
                
                // Online indicator
                if user.online {
                    Circle()
                        .fill(AppTheme.AccentColors.success)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.GradientColors.deepBlack, lineWidth: 3)
                        )
                        .offset(x: 4, y: 4)
                }
            }
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 3)
            )
            
            // Name and status
            VStack(spacing: 8) {
                Text(user.name ?? "Unknown User")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if user.status == "suspended" {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("SUSPENDED")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.AccentColors.error)
                    )
                } else {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(user.online ? AppTheme.AccentColors.success : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(user.online ? "Active now" : "Offline")
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Stats
    
    private var userStatsSection: some View {
        HStack(spacing: 16) {
            StatBox(
                icon: "bubble.left.fill",
                title: "Messages",
                value: "\(user.messageCount)",
                color: AppTheme.AccentColors.primary
            )
            
            StatBox(
                icon: "calendar",
                title: "Member Since",
                value: formatDate(user.createdAt),
                color: AppTheme.AccentColors.secondary
            )
        }
    }
    
    // MARK: - Account Info
    
    private var accountInfoSection: some View {
        VStack(spacing: 16) {
            Text("Account Information")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InfoRow(icon: "envelope.fill", title: "Email", value: user.email ?? "N/A")
            InfoRow(icon: "person.fill", title: "User ID", value: user.id)
            InfoRow(icon: "shield.fill", title: "Role", value: user.userRole?.rawValue.capitalized ?? "User")
            
            if let lastActive = user.lastActive {
                InfoRow(icon: "clock.fill", title: "Last Active", value: formatFullDate(lastActive))
            }
            
            if let suspendedAt = user.suspendedAt {
                InfoRow(icon: "exclamationmark.triangle.fill", title: "Suspended At", value: formatFullDate(suspendedAt))
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Text("Actions")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showSuspendConfirmation = true
            }) {
                HStack {
                    Image(systemName: user.status == "suspended" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text(user.status == "suspended" ? "Unsuspend User" : "Suspend User")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(user.status == "suspended" ? AppTheme.AccentColors.success : AppTheme.AccentColors.error)
                )
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.6 : 1.0)
        }
    }
    
    // MARK: - Helpers
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.AccentColors.primary,
                        AppTheme.AccentColors.secondary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func handleSuspendAction() async {
        isProcessing = true
        
        let success = await adminVM.suspendUser(
            userId: user.id,
            suspended: user.status != "suspended",
            reason: suspendReason.isEmpty ? nil : suspendReason
        )
        
        isProcessing = false
        
        if success {
            dismiss()
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.AccentColors.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(AppTheme.AccentColors.primary.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.06))
        )
    }
}
