//
//  ReactionsView.swift
//  vynqtalk
//
//  Display reactions on a message
//

import SwiftUI

struct ReactionsView: View {
    let reactions: [Reaction]
    let currentUserId: String
    
    // Group reactions by emoji
    private var groupedReactions: [(emoji: String, count: Int, hasUserReacted: Bool)] {
        let grouped = Dictionary(grouping: reactions, by: { $0.emoji })
        return grouped.map { emoji, reactionList in
            let hasUserReacted = reactionList.contains { reaction in
                if let userId = reaction.userId {
                    return userId == currentUserId
                } else if let user = reaction.user, let id = user.id {
                    return id == currentUserId
                }
                return false
            }
            return (emoji: emoji, count: reactionList.count, hasUserReacted: hasUserReacted)
        }.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        if !reactions.isEmpty {
            HStack(spacing: 6) {
                ForEach(groupedReactions, id: \.emoji) { item in
                    HStack(spacing: 4) {
                        Text(item.emoji)
                            .font(.system(size: 14))
                        
                        if item.count > 1 {
                            Text("\(item.count)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(item.hasUserReacted ? .white : .white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(item.hasUserReacted ? 
                                  AppTheme.AccentColors.primary.opacity(0.3) : 
                                  Color.white.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(item.hasUserReacted ? 
                                           AppTheme.AccentColors.primary : 
                                           Color.white.opacity(0.2), 
                                           lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}
