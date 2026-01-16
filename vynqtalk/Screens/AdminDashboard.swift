//
//  AdminDashboard.swift
//  vynqtalk
//
//  Admin dashboard overview screen - Professional redesign
//

import SwiftUI

struct AdminDashboard: View {
    @StateObject private var adminVM = AdminViewModel()
    @StateObject private var adminWS = AdminWSManager()
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            AppTheme.BackgroundColors.primary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header with real-time status
                    headerSection
                    
                    // Key metrics in compact grid
                    if let stats = adminVM.dashboardStats {
                        metricsGrid(stats: stats)
                        
                        // Activity chart
                        activitySection(stats: stats)
                    } else if adminVM.isLoading {
                        ProgressView()
                            .tint(AppTheme.AccentColors.primary)
                            .padding(.top, 40)
                    }
                    
                    // Quick actions grid
                    quickActionsGrid
                }
                .padding(20)
            }
            .opacity(appeared ? 1 : 0)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await adminVM.loadDashboardStats()
            adminWS.connect()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
        .onDisappear {
            adminWS.disconnect()
        }
        .onChange(of: adminWS.userStatusUpdate) { _, update in
            if let update = update { adminVM.handleUserStatusUpdate(update) }
        }
        .onChange(of: adminWS.messageUpdate) { _, update in
            if let update = update { adminVM.handleMessageUpdate(update) }
        }
        .onChange(of: adminWS.newUser) { _, user in
            if let user = user { adminVM.handleNewUser(user) }
        }
        .refreshable {
            await adminVM.loadDashboardStats()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Admin Dashboard")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(adminWS.isConnected ? AppTheme.AccentColors.success : AppTheme.TextColors.tertiary)
                            .frame(width: 6, height: 6)
                        
                        Text(adminWS.isConnected ? "Live" : "Connecting...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.TextColors.secondary)
                    }
                }
                
                Spacer()
                
                // Refresh button
                Button(action: {
                    Task { await adminVM.loadDashboardStats() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.TextColors.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(AppTheme.SurfaceColors.base)
                        )
                }
            }
        }
    }
    
    // MARK: - Metrics Grid
    
    private func metricsGrid(stats: AdminDashboardStats) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            CompactMetricCard(
                icon: "person.3.fill",
                title: "Total Users",
                value: "\(stats.totalUsers)",
                color: AppTheme.AccentColors.primary
            )
            
            CompactMetricCard(
                icon: "circle.fill",
                title: "Online",
                value: "\(stats.activeUsers)",
                color: AppTheme.AccentColors.success
            )
            
            CompactMetricCard(
                icon: "bubble.left.fill",
                title: "Messages",
                value: formatNumber(stats.totalMessages),
                color: Color.cyan
            )
            
            CompactMetricCard(
                icon: "clock.fill",
                title: "Last 24h",
                value: formatNumber(stats.messagesLast24h),
                color: Color.orange
            )
        }
    }
    
    // MARK: - Activity Section
    
    private func activitySection(stats: AdminDashboardStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            VStack(spacing: 16) {
                ActivityRow(
                    icon: "person.badge.plus.fill",
                    title: "New users today",
                    value: "\(stats.newUsersToday)",
                    color: AppTheme.AccentColors.primary
                )
                
                ActivityRow(
                    icon: "paperplane.fill",
                    title: "Messages today",
                    value: formatNumber(stats.messagesLast24h),
                    color: Color.cyan
                )
                
                ActivityRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Active users",
                    value: "\(stats.activeUsers) / \(stats.totalUsers)",
                    color: AppTheme.AccentColors.success
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.SurfaceColors.base)
            )
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                NavigationLink {
                    AdminUserList()
                } label: {
                    QuickActionButton(
                        icon: "person.2.fill",
                        title: "Users",
                        color: AppTheme.AccentColors.primary
                    )
                }
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Analytics",
                    color: Color.purple
                )
                
                QuickActionButton(
                    icon: "bell.fill",
                    title: "Notifications",
                    color: Color.orange
                )
                
                QuickActionButton(
                    icon: "gearshape.fill",
                    title: "Settings",
                    color: AppTheme.TextColors.secondary
                )
            }
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

// MARK: - Compact Metric Card

struct CompactMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.SurfaceColors.base)
        )
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.SurfaceColors.base)
        )
    }
}
