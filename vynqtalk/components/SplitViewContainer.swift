//
//  SplitViewContainer.swift
//  vynqtalk
//
//  Split view container for iPad layout
//

import SwiftUI

struct SplitViewContainer<Sidebar: View, Detail: View>: View {
    let sidebar: Sidebar
    let detail: Detail
    let sidebarWidth: CGFloat
    
    init(
        sidebarWidth: CGFloat = 350,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebarWidth = sidebarWidth
        self.sidebar = sidebar()
        self.detail = detail()
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar (User List)
                sidebar
                    .frame(width: min(sidebarWidth, geometry.size.width * 0.4))
                    .background(AppTheme.GradientColors.deepBlack)
                
                // Divider
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 1)
                
                // Detail (Chat)
                detail
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.GradientColors.deepBlack)
            }
        }
    }
}

/// Adaptive container that switches between split view (iPad) and navigation (iPhone)
struct AdaptiveSplitView<Sidebar: View, Detail: View, EmptyDetail: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let sidebar: Sidebar
    let detail: Detail?
    let emptyDetail: EmptyDetail
    let sidebarWidth: CGFloat
    
    init(
        sidebarWidth: CGFloat = 350,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail?,
        @ViewBuilder emptyDetail: () -> EmptyDetail
    ) {
        self.sidebarWidth = sidebarWidth
        self.sidebar = sidebar()
        self.detail = detail()
        self.emptyDetail = emptyDetail()
    }
    
    var isIPad: Bool {
        return DeviceType.current == .iPad
    }
    
    var body: some View {
        if isIPad {
            // iPad: Split view
            SplitViewContainer(sidebarWidth: sidebarWidth) {
                sidebar
            } detail: {
                if let detail = detail {
                    detail
                } else {
                    emptyDetail
                }
            }
        } else {
            // iPhone: Navigation stack
            sidebar
        }
    }
}

/// Empty state for split view when no chat is selected
struct EmptyChatDetailView: View {
    var body: some View {
        ZStack {
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text("Select a conversation")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Choose a chat from the list to start messaging")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
        }
    }
}
