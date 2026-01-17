//
//  UltraHomeScreen.swift
//  vynqtalk
//
//  Ultra-Refined Home Screen - Maximum Apple Quality
//  Perfect calmness, zero visual noise
//

import SwiftUI
import Foundation

struct UltraHomeScreen: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var wsM: WebSocketManager
    
    @State private var searchText = ""
    @State private var appeared = false
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return userVM.users
        }
        return userVM.users.filter { user in
            (user.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (user.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        ZStack {
            // Perfect background
            UltraTheme.Backgrounds.gradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Perfect header
                ultraHeader
                
                // Perfect search
                ultraSearch
                
                // Perfect conversations
                ultraConversations
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle) {
                appeared = true
            }
        }
        .task {
            await userVM.loadUsers()
        }
    }
    
    // MARK: - Perfect Header
    
    private var ultraHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Messages")
                    .font(UltraTheme.Typography.largeTitle)
                    .foregroundColor(UltraTheme.Text.primary)
                
                Text("Stay connected")
                    .font(UltraTheme.Typography.caption)
                    .foregroundColor(UltraTheme.Text.tertiary)
            }
            
            Spacer()
            
            // Perfect profile button
            Button(action: {}) {
                Circle()
                    .fill(UltraTheme.Glass.surface)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(UltraTheme.Text.secondary)
                    )
            }
        }
        .padding(.horizontal, UltraTheme.Layout.l)
        .padding(.top, UltraTheme.Layout.s)
        .padding(.bottom, UltraTheme.Layout.l)
    }
    
    // MARK: - Perfect Search
    
    private var ultraSearch: some View {
        UltraSearchBar(text: $searchText)
            .padding(.horizontal, UltraTheme.Layout.l)
            .padding(.bottom, UltraTheme.Layout.m)
    }
    
    // MARK: - Perfect Conversations
    
    private var ultraConversations: some View {
        ScrollView {
            LazyVStack(spacing: UltraTheme.Layout.s) {
                if userVM.isLoading {
                    UltraLoadingView()
                        .padding(.top, 40)
                } else if filteredUsers.isEmpty {
                    UltraEmptyView()
                        .padding(.top, 40)
                } else {
                    ForEach(filteredUsers) { user in
                        UltraConversationCard(user: user) {
                            handleUserTap(user)
                        }
                    }
                }
            }
            .padding(.horizontal, UltraTheme.Layout.l)
            .padding(.bottom, 100)
        }
    }
    
    private func handleUserTap(_ user: User) {
        guard let id = user.id else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        nav.push(.chat(
            userId: id,
            name: user.name ?? "Chat",
            avatar: user.avatar,
            lastActive: user.lastActive
        ))
    }
}

// MARK: - Ultra Search Bar

struct UltraSearchBar: View {
    @Binding var text: String
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack(spacing: UltraTheme.Layout.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(focused ? UltraTheme.Accent.primary : UltraTheme.Text.tertiary)
            
            TextField("Search", text: $text)
                .font(UltraTheme.Typography.body)
                .foregroundColor(UltraTheme.Text.primary)
                .focused($focused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(UltraTheme.Text.tertiary)
                }
            }
        }
        .padding(UltraTheme.Layout.m)
        .ultraGlass()
        .animation(UltraTheme.Motion.gentle, value: focused)
        .animation(UltraTheme.Motion.gentle, value: text.isEmpty)
    }
}

// MARK: - Ultra Conversation Card

struct UltraConversationCard: View {
    @EnvironmentObject var wsM: WebSocketManager
    let user: User
    let action: () -> Void
    
    @State private var pressed = false
    
    private var isOnline: Bool {
        guard let userId = user.id else { return false }
        return wsM.isUserOnline(userId)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: UltraTheme.Layout.m) {
                // Perfect avatar
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: user.avatarURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(UltraTheme.Glass.elevated)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(UltraTheme.Text.secondary)
                            )
                    }
                    .frame(width: UltraTheme.Layout.avatar, height: UltraTheme.Layout.avatar)
                    .clipShape(Circle())
                    
                    // Perfect online indicator
                    if isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(UltraTheme.Backgrounds.primary, lineWidth: 2)
                            )
                    }
                }
                
                // Perfect content
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name ?? "Unknown")
                        .font(UltraTheme.Typography.body)
                        .foregroundColor(UltraTheme.Text.primary)
                    
                    Text(user.bio ?? user.email ?? "Start a conversation")
                        .font(UltraTheme.Typography.caption)
                        .foregroundColor(UltraTheme.Text.tertiary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(UltraTheme.Layout.m)
            .ultraCard()
            .scaleEffect(pressed ? 0.98 : 1.0)
            .animation(UltraTheme.Motion.spring, value: pressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            pressed = pressing
        }, perform: {})
    }
}

// MARK: - Ultra Loading View

struct UltraLoadingView: View {
    var body: some View {
        VStack(spacing: UltraTheme.Layout.m) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: UltraTheme.Accent.primary))
            
            Text("Loading conversations...")
                .font(UltraTheme.Typography.caption)
                .foregroundColor(UltraTheme.Text.tertiary)
        }
        .padding(UltraTheme.Layout.xl)
        .ultraCard()
    }
}

// MARK: - Ultra Empty View

struct UltraEmptyView: View {
    var body: some View {
        VStack(spacing: UltraTheme.Layout.l) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(UltraTheme.Text.quaternary)
            
            VStack(spacing: UltraTheme.Layout.s) {
                Text("No conversations yet")
                    .font(UltraTheme.Typography.title)
                    .foregroundColor(UltraTheme.Text.primary)
                
                Text("Start chatting with someone!")
                    .font(UltraTheme.Typography.caption)
                    .foregroundColor(UltraTheme.Text.tertiary)
            }
        }
        .padding(UltraTheme.Layout.xl)
        .ultraCard()
    }
}