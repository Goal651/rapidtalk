//
//  Welcome.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject var nav: NavigationCoordinator
    
    // MARK: - Animation State
    
    @State private var wave = false
    @State private var logoAppeared = false
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var buttonsAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = ResponsiveSpacing(screenWidth: geometry.size.width)
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()
                
                VStack(spacing: isLandscape ? AppTheme.Spacing.l : spacing.sectionSpacing) {
                    
                    if !isLandscape {
                        Spacer()
                    }
                    
                    // Logo/Icon with entrance animation
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: (isLandscape ? 60 : 80) * spacing.iconScale,
                            height: (isLandscape ? 60 : 80) * spacing.iconScale
                        )
                        .foregroundColor(AppTheme.AccentColors.primary)
                        .opacity(logoAppeared ? 1 : 0)
                        .scaleEffect(logoAppeared ? 1 : 0.5)
                        .onAppear {
                            withAnimation(
                                AppTheme.AnimationCurves.componentAppearance
                                .delay(0.5)
                            ) {
                                logoAppeared = true
                            }
                        }
                    
                    // Title and subtitle with entrance animations
                    VStack(spacing: AppTheme.Spacing.m) {
                        Text("Welcome to VynqTalk")
                            .font(isLandscape ? AppTheme.Typography.title : AppTheme.Typography.largeTitle)
                            .foregroundColor(AppTheme.TextColors.primary)
                            .multilineTextAlignment(.center)
                            .opacity(titleAppeared ? 1 : 0)
                            .offset(y: titleAppeared ? 0 : 20)
                            .onAppear {
                                withAnimation(
                                    AppTheme.AnimationCurves.componentAppearance
                                    .delay(0.7)
                                ) {
                                    titleAppeared = true
                                }
                            }
                        
                        Text("Connect with friends")
                            .font(isLandscape ? AppTheme.Typography.body : AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.TextColors.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(subtitleAppeared ? 1 : 0)
                            .onAppear {
                                withAnimation(
                                    AppTheme.AnimationCurves.componentAppearance
                                    .delay(0.9)
                                ) {
                                    subtitleAppeared = true
                                }
                            }
                    }
                    .padding(.horizontal, spacing.horizontalPadding)
                    
                    // Waving hand icon with continuous animation (hide in landscape)
                    if !isLandscape {
                        Image(systemName: "hand.wave.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60 * spacing.iconScale, height: 60 * spacing.iconScale)
                            .foregroundColor(AppTheme.AccentColors.warning)
                            .rotationEffect(.degrees(wave ? 15 : -15))
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                value: wave
                            )
                            .opacity(subtitleAppeared ? 1 : 0)
                            .onAppear {
                                wave = true
                            }
                    }
                    
                    if !isLandscape {
                        Spacer()
                    }
                    
                    // Buttons with entrance animations
                    VStack(spacing: spacing.formSpacing) {
                        // Primary button - Get Started
                        CustomButton(
                            title: "Get Started",
                            style: .primary,
                            action: {
                                nav.push(.register)
                            }
                        )
                        .padding(.horizontal, spacing.horizontalPadding)
                        .opacity(buttonsAppeared ? 1 : 0)
                        .offset(y: buttonsAppeared ? 0 : 20)
                        .onAppear {
                            withAnimation(
                                AppTheme.AnimationCurves.componentAppearance
                                .delay(1.1)
                            ) {
                                buttonsAppeared = true
                            }
                        }
                        
                        // OR Divider
                        HStack {
                            line
                            Text("OR")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(AppTheme.TextColors.secondary)
                                .fontWeight(.medium)
                            line
                        }
                        .padding(.horizontal, spacing.horizontalPadding)
                        .opacity(buttonsAppeared ? 1 : 0)
                        
                        // Secondary button - Sign In
                        CustomButton(
                            title: "Sign In",
                            style: .secondary,
                            action: {
                                nav.push(.login)
                            }
                        )
                        .padding(.horizontal, spacing.horizontalPadding)
                        .opacity(buttonsAppeared ? 1 : 0)
                        .offset(y: buttonsAppeared ? 0 : 20)
                    }
                    .padding(.bottom, spacing.bottomPadding)
                }
                .frame(maxWidth: spacing.contentMaxWidth)
                .frame(width: geometry.size.width)
            }
        }
    }
    
    // MARK: - Helper Views
    
    /// Clean divider line
    private var line: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(AppTheme.TextColors.tertiary)
    }
}
