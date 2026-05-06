# SoberLife iOS app (Xcode)

## Open and run
1. Open `SoberLife.xcodeproj` in Xcode (16+ recommended).
2. Set your **Team** on the `SoberLife` target (Signing & Capabilities).
3. In the Supabase dashboard, enable **Email** under **Authentication → Providers** (and adjust sign-up / email confirmation to match how you want onboarding to behave).
4. Configure Supabase for real auth/chat:
   - Either edit **Build Settings** → User-Defined: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,  
   - Or copy `Config/Secrets.example.xcconfig` to **`Config/Secrets.xcconfig`** (gitignored), put secrets there, and set **Based on Configuration File** for Debug/Release to that file.
5. Add a **1024×1024** icon under `App/Assets.xcassets/AppIcon` before archiving for TestFlight (App Store Connect rejects missing marketing icon).

The app signs in with **email and password** via Supabase Auth (`/auth/v1/token` password grant and `/auth/v1/signup`). There is no Sign in with Apple entitlement in this target.

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
