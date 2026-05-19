# Untap - NFC App Blocker

An iOS app that blocks distracting apps when you tap an NFC card, and unblocks them only when you tap again.

## Features

- **NFC Tap Control**: Tap your NFC card to toggle app blocking on/off
- **Screen Time Integration**: Uses Apple's official Screen Time API for reliable blocking
- **Custom Blocking Rules**: Create rules for different times (Morning Focus, Wind-down, etc.)
- **Multiple NFC Tags**: Pair different NFC tags to different blocking rules
- **Beautiful UI**: Clean, calming design with sage green accent colors
- **Stats & Tracking**: See time saved, blocks prevented, and maintain streaks
- **Social Features**: Compare progress with friends (optional)

## Requirements

- iOS 17.0+
- iPhone 7 or later (NFC capable)
- Any NFC tag/card (NTAG213, NTAG215, NTAG216, or similar)

## Setup Instructions

### 1. Open in Xcode

Open `Untap.xcodeproj` in Xcode 15 or later.

### 2. Configure Signing

1. Select the **Untap** target
2. Go to **Signing & Capabilities**
3. Select your **Team**
4. Change the **Bundle Identifier** to something unique (e.g., `com.yourname.Untap`)

### 3. Add Shield Extension (Important!)

The Shield extension is required for the blocking UI. In Xcode:

1. File → New → Target
2. Select **Shield Configuration Extension**
3. Name it `UntapShield`
4. Copy the code from `UntapShield/ShieldConfigurationExtension.swift` into the new target

### 4. Request Family Controls Capability

**Important**: Apple requires approval for the Family Controls capability.

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**
3. Select your App ID
4. Enable **Family Controls** capability
5. Submit the request form explaining your app's use case

For development/testing, you can use the **Development** profile which allows testing without full approval.

### 5. Add Fonts (Optional)

For the exact design match, add these fonts to your project:
- Instrument Serif (Regular, Italic)
- Geist (Regular, Medium, SemiBold)
- Geist Mono (Regular, Medium)

Download from Google Fonts and add to the project, then update `Info.plist` with:
```xml
<key>UIAppFonts</key>
<array>
    <string>InstrumentSerif-Regular.ttf</string>
    <string>InstrumentSerif-Italic.ttf</string>
    <string>Geist-Regular.ttf</string>
    <string>Geist-Medium.ttf</string>
    <string>GeistMono-Regular.ttf</string>
</array>
```

If fonts aren't added, the app will fall back to system fonts.

### 6. Build & Run

1. Connect your iPhone
2. Select your device in Xcode
3. Build and run (Cmd+R)
4. Grant Screen Time permissions when prompted

## How to Use

### First Launch
1. Grant Screen Time permissions when the app requests them
2. Go to **Blocks** tab and select which apps to block
3. Create or edit rules for different times of day

### Pair an NFC Tag
1. Go to **Blocks** tab
2. Tap **Pair tag**
3. Hold your NFC card near the top of your iPhone
4. Name the tag and assign it to a rule

### Start a Focus Session
1. Tap the main button on the Home screen
2. Hold your NFC card near your iPhone
3. Selected apps are now blocked!
4. Tap the card again to unblock

## Architecture

```
Untap/
├── UntapApp.swift          # App entry point
├── ContentView.swift       # Main container with tab bar
├── Theme.swift             # Colors, fonts, and styles
├── Views/
│   ├── HomeView.swift      # Main dashboard with NFC tap
│   ├── BlocksView.swift    # Manage blocking rules
│   ├── SocialView.swift    # Friends & leaderboards
│   └── ProfileView.swift   # Settings & profile
├── Managers/
│   ├── NFCManager.swift    # NFC reading & tag pairing
│   └── AppBlockingManager.swift  # Screen Time integration
└── Assets.xcassets/        # App icons & colors

UntapShield/
└── ShieldConfigurationExtension.swift  # Blocked app UI
```

## Frameworks Used

- **SwiftUI** - UI framework
- **CoreNFC** - NFC tag reading
- **FamilyControls** - Screen Time authorization
- **ManagedSettings** - App blocking
- **DeviceActivity** - Activity monitoring

## Troubleshooting

### NFC not working
- Ensure you're using iPhone 7 or later
- Hold the NFC tag near the top of your phone
- Check that Background Tag Reading is enabled in Settings

### Apps not blocking
- Ensure Screen Time permissions are granted
- Check that you've selected apps in the Blocks tab
- Verify Family Controls entitlement is properly configured

### Build errors
- Clean build folder (Cmd+Shift+K)
- Delete derived data
- Ensure Xcode 15+ is installed
- Check signing configuration

## License

MIT License - feel free to use and modify!
