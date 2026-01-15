//
//  AdminDashboard.swift
//  vynqtalk
//
//  Admin dashboard overview screen
//

import SwiftUI

struct AdminDashboard: View {
    @StateObject private var adminVM = AdminViewModel()
    @StateObject private var adminWS = AdminWSManager()
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Stats Cards
                    if let stats = adminVM.dashboardStats {
                        statsSection(stats: stats)
                    } else if adminVM.isLoading {
                        ProgressView()
                            .tint(AppTheme.AccentColors.primary)
                            .padding(.top, 40)
                    }
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .navigationBarBackButtonHidden()
        .task {
            await adminVM.loadDashboardStats()
            adminWS.connect()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .onDisappear {
            adminWS.disconnect()
        }
        .onChange(of: adminWS.userStatusUpdate) { _, update in
            if let update = update {
                adminVM.handleUserStatusUpdate(update)
            }
        }
        .onChange(of: adminWS.messageUpdate) { _, update in
            if let update = update {
                adminVM.handleMessageUpdate(update)
            }
        }
        .onChange(of: adminWS.newUser) { _, user in
            if let user = user {
                adminVM.handleNewUser(user)
            }
        }
        .refreshable {
            await adminVM.loadDashboardStats()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.AccentColors.primary)
                
                Text("Admin Dashboard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 8) {
                Circle()
                    .fill(adminWS.isConnected ? AppTheme.AccentColors.success : .gray)
                    .frame(width: 8, height: 8)
                
                Text(adminWS.isConnected ? "Real-time connected" : "Connecting...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Stats Section
    
    private func statsSection(stats: AdminDashboardStats) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "person.3.fill",
                    title: "Total Users",
                    value: "\(stats.totalUsers)",
                    color: AppTheme.AccentColors.primary
                )
                
                StatCard(
                    icon: "circle.fill",
                    title: "Active Now",
                    value: "\(stats.activeUsers)",
                    color: AppTheme.AccentColors.success
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Total Messages",
                    value: formatNumber(stats.totalMessages),
                    color: AppTheme.AccentColors.secondary
                )
                
                StatCard(
                    icon: "person.badge.plus.fill",
                    title: "New Today",
                    value: "\(stats.newUsersToday)",
                    color: Color.orange
                )
            }
            
            // Last 24h messages (full width)
            StatCard(
                icon: "clock.fill",
                title: "Messages (24h)",
                value: formatNumber(stats.messagesLast24h),
                color: Color.cyan,
                fullWidth: true
            )
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            NavigationLink(destination: AdminUserList()) {
                QuickActionCard(
                    icon: "person.2.fill",
                    title: "Manage Users",
                    subtitle: "View and manage all users",
                    color: AppTheme.AccentColors.primary
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000.0)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var fullWidth: Bool = false
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(isPressed ? 0.15 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
