# SoberLife iOS app (Xcode)

## Open and run
1. Open `SoberLife.xcodeproj` in Xcode (16+ recommended).
2. Set your **Team** on the `SoberLife` target (Signing & Capabilities).
3. Add **Sign in with Apple** capability if Xcode prompts (entitlements file already includes it).
4. Configure Supabase for real auth/chat:
   - Either edit **Build Settings** → User-Defined: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,  
   - Or copy `Config/Shared.xcconfig` to a **local** `Config/Local.xcconfig` (gitignored), put secrets there, and set **Based on Configuration File** for the project to that file.
5. Add a **1024×1024** icon under `App/Assets.xcassets/AppIcon` before archiving for TestFlight (App Store Connect rejects missing marketing icon).

## Command-line build (Simulator)
From repo root:

```bash
cd ios
xcodebuild -project SoberLife.xcodeproj -scheme SoberLife \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug build
```

Pick any installed simulator from **Xcode → Window → Devices and Simulators**.

## TestFlight (outline)
1. Create an App ID + App in App Store Connect matching **Bundle Identifier** (`com.soberlife.app` by default, change in target settings if needed).
2. Archive: **Product → Archive** with a **Release** configuration and a real **Development Team**.
3. Distribute to TestFlight; complete export compliance and beta review as required.

The Swift package at the repo root (`Package.swift`) is linked as a **local Swift Package** (`relativePath = ..` from this `ios` folder).
