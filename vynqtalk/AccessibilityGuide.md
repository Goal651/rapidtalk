# VynqTalk Accessibility Guide

## Overview

This guide documents the accessibility features implemented in VynqTalk to ensure the app is usable by everyone, including users with disabilities.

## WCAG Compliance

### Contrast Ratios

All text and interactive elements meet WCAG AA standards:
- Normal text: Minimum 4.5:1 contrast ratio
- Large text (18pt+ or 14pt+ bold): Minimum 3:1 contrast ratio

#### Validation Functions

```swift
// Check contrast ratio between two colors
let ratio = AppTheme.contrastRatio(foreground: textColor, background: backgroundColor)

// Verify WCAG AA compliance
let meetsStandard = AppTheme.meetsWCAGAA(foreground: textColor, background: backgroundColor)

// Run full theme validation
let results = AppTheme.validateThemeContrast()
```

### Touch Target Sizes

All interactive elements meet iOS minimum touch target requirements:
- Minimum size: 44x44 points
- Comfortable size: 48x48 points
- Large size (primary actions): 56x56 points

#### Helper Modifiers

```swift
// Apply minimum touch target
Button("Action") { }
    .minimumTouchTarget()

// Apply comfortable touch target
Button("Action") { }
    .comfortableTouchTarget()
```


## VoiceOver Support

### Component Accessibility Labels

#### CustomButton
- Supports custom accessibility labels and hints
- Announces button state (disabled, loading)
- Example:
```swift
CustomButton(
    title: "Sign In",
    style: .primary,
    action: { },
    accessibilityLabel: "Sign in to your account",
    accessibilityHint: "Double tap to sign in"
)
```

#### CustomTextField
- Provides descriptive labels for text entry
- Announces field type (secure/regular)
- Announces current value
- Clear button has descriptive label
- Example:
```swift
CustomTextField(
    label: "Email",
    placeholder: "Enter your email",
    text: $email,
    accessibilityHint: "Enter your email address to sign in"
)
```

#### BackButton
- Clear navigation context
- Announces "Back" with hint "Returns to the previous screen"

#### UserComponent
- Combines all user information into coherent description
- Announces: name, online status, email, bio, and status
- Example output: "John Doe, online, john@example.com, iOS Developer"

#### MessageBubble
- Provides context about sender and time
- Announces: sender name, message content, and timestamp
- Example output: "You said Hello there at 10:30"

#### LoadingView
- Announces "Loading" state
- Includes optional message for context


## Testing Accessibility

### Manual Testing with VoiceOver

1. Enable VoiceOver on your iOS device:
   - Settings > Accessibility > VoiceOver > On
   - Or use triple-click home/side button shortcut

2. Test navigation:
   - Swipe right/left to move between elements
   - Double-tap to activate buttons
   - Three-finger swipe to scroll

3. Verify all interactive elements:
   - Have descriptive labels
   - Announce their purpose clearly
   - Provide hints when needed
   - Are easily discoverable

### Automated Testing

Run accessibility tests:
```bash
xcodebuild test -scheme vynqtalk -destination 'platform=iOS Simulator,name=iPhone 15'
```

Tests verify:
- Contrast ratios meet WCAG AA standards
- Touch targets meet minimum size requirements
- Accessibility modifiers are properly applied

## Best Practices

1. **Always provide accessibility labels** for custom views and images
2. **Use semantic traits** (.isButton, .isHeader, etc.)
3. **Group related elements** with .accessibilityElement(children: .combine)
4. **Test with VoiceOver** regularly during development
5. **Maintain contrast ratios** when adding new colors
6. **Ensure touch targets** are at least 44x44 points
7. **Provide hints** for complex interactions
8. **Announce dynamic changes** with accessibility notifications

## Resources

- [Apple Accessibility Guidelines](https://developer.apple.com/accessibility/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
