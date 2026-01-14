//
//  LoadingView.swift
//  vynqtalk
//
//  Reusable loading indicator component with multiple styles
//

import SwiftUI

struct LoadingView: View {
    
    // MARK: - Loading Style
    
    enum Style {
        case spinner        // Circular progress indicator
        case dots          // Three bouncing dots
        case pulse         // Pulsing circle
    }
    
    // MARK: - Properties
    
    var message: String? = nil
    var style: Style = .spinner
    var color: Color = AppTheme.TextColors.primary
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            // Loading indicator
            Group {
                switch style {
                case .spinner:
                    SpinnerView(color: color)
                case .dots:
                    DotsView(color: color)
                case .pulse:
                    PulseView(color: color)
                }
            }
            
            // Optional message
            if let message = message {
                Text(message)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Spinner View

private struct SpinnerView: View {
    let color: Color
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: color))
            .scaleEffect(1.5)
    }
}

// MARK: - Dots View

private struct DotsView: View {
    let color: Color
    
    @State private var animationPhase: Int = 0
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .scaleEffect(animationPhase == index ? 1.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Pulse View

private struct PulseView: View {
    let color: Color
    
    @State private var isPulsing: Bool = false
    
    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 1)
            
            // Middle pulse ring
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 3)
                .frame(width: 50, height: 50)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0 : 1)
            
            // Inner circle
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .scaleEffect(isPulsing ? 0.9 : 1.0)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xxl) {
                // Spinner style
                LoadingView(
                    message: "Loading...",
                    style: .spinner
                )
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Dots style
                LoadingView(
                    message: "Please wait",
                    style: .dots
                )
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Pulse style
                LoadingView(
                    message: "Processing",
                    style: .pulse
                )
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Without message
                LoadingView(style: .spinner)
            }
            .padding(AppTheme.Spacing.l)
        }
    }
}
