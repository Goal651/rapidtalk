//
//  AdminCharts.swift
//  vynqtalk
//
//  Chart components for admin dashboard analytics
//

import SwiftUI

// MARK: - User Growth Line Chart

struct UserGrowthChart: View {
    let data: [UserGrowthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Growth")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            // Simple line chart representation
            VStack(spacing: 8) {
                HStack {
                    Text("Users")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                    Spacer()
                    if let maxCount = data.max(by: { $0.count < $1.count })?.count {
                        Text("\(maxCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.AccentColors.primary)
                    }
                }
                
                // Visual bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(data.suffix(7)) { item in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(AppTheme.AccentColors.primary)
                                .frame(width: 20, height: CGFloat(item.count) * 2)
                                .cornerRadius(2)
                            
                            Text(String(item.date.suffix(2)))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.TextColors.tertiary)
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(16)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(12)
    }
}

// MARK: - Message Activity Chart

struct MessageActivityChart: View {
    let data: [MessageActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Activity")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Messages")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                    Spacer()
                    if let maxCount = data.max(by: { $0.count < $1.count })?.count {
                        Text("\(maxCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.cyan)
                    }
                }
                
                // Visual bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(data.suffix(7)) { item in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.cyan)
                                .frame(width: 20, height: max(CGFloat(item.count) * 0.5, 8))
                                .cornerRadius(2)
                            
                            Text(String(item.date.suffix(2)))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.TextColors.tertiary)
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(16)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(12)
    }
}

// MARK: - Message Type Distribution Chart

struct MessageTypeChart: View {
    let data: [MessageTypeData]
    
    private var colors: [Color] {
        [AppTheme.AccentColors.primary, Color.cyan, Color.orange, Color.purple, AppTheme.AccentColors.success]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Types")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        // Color indicator
                        Circle()
                            .fill(colors[index % colors.count])
                            .frame(width: 12, height: 12)
                        
                        // Type info
                        HStack(spacing: 6) {
                            Text(item.emoji)
                                .font(.system(size: 14))
                            
                            Text(item.displayName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.secondary)
                        }
                        
                        Spacer()
                        
                        // Count
                        Text("\(item.count)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.TextColors.primary)
                        
                        // Visual bar
                        Rectangle()
                            .fill(colors[index % colors.count].opacity(0.3))
                            .frame(width: max(CGFloat(item.count) * 0.5, 20), height: 4)
                            .cornerRadius(2)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(12)
    }
}

// MARK: - Analytics Overview Cards

struct AnalyticsCard: View {
    let title: String
    let value: String
    let change: String?
    let changeColor: Color
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                Spacer()
                
                if let change = change {
                    Text(change)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(changeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(changeColor.opacity(0.15))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.secondary)
            }
        }
        .padding(16)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(12)
    }
}