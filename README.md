# 🏍️ MotoStack

> A production-grade Flutter ride tracker built for the **Royal Enfield Meteor 350 Supernova** — crafted by a Senior Flutter Developer in Ahmedabad, India.

---

## 📱 Screenshots

| Gate / Lock | Dashboard | Tracking | Settings |
|:-----------:|:---------:|:--------:|:--------:|
| *(biometric + GPS gate)* | *(3D bike + stats)* | *(live OSM map)* | *(lang + theme)* |

> Place your screenshots in `assets/images/` and update the table above.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🔐 Biometric Lock | Face ID / Fingerprint / PIN — blocks app entry until authenticated |
| 📍 Location Gate | Fetches real GPS on launch — app won't open without location permission |
| 🏍️ 3D Bike Viewer | Interactive `.glb` model of the Meteor 350 via `flutter_3d_controller` |
| 🗺️ Live Ride Tracking | OSM tiles (100% free), orange polyline trail, blue dot current position |
| ⛽ Fuel Wallet | Auto-deducts ₹3.03/km (Meteor 350 @ 35 km/l, ₹106/l petrol) |
| 📏 Daily 12 km Goal | Progress bar tracking your fixed Ahmedabad commute loop |
| 🌡️ Heat Warning | Warns when Ahmedabad temperature exceeds 40°C (Open-Meteo API, no key needed) |
| 🌗 AMOLED Dark / Light | Theme toggle with pure black AMOLED dark mode |
| 🌐 Hindi / English | Full localization via `easy_localization` — switchable at runtime |
| 📳 Haptic Ignition | `HapticFeedback.heavyImpact()` on the ignition button |
| 🎬 OpenContainer Transition | Shared-element style transition from dashboard to tracking map |

---

## 🏗️ Architecture

Feature-First Clean Architecture with Riverpod 3.0 code generation.

```
lib/
├── main.dart                          # App entry, EasyLocalization + ProviderScope
│
├── core/
│   ├── providers/
│   │   ├── app_gate_provider.dart     # Biometric → GPS gate sequencer
│   │   └── locale_provider.dart      # Runtime locale switcher
│   ├── theme/
│   │   ├── app_theme.dart            # AMOLED dark + light ThemeData
│   │   └── theme_provider.dart       # ThemeNotifier (@riverpod)
│   └── utils/
│       └── weather_helper.dart       # Open-Meteo fetch + 40°C threshold
│
└── features/
    ├── gate/
    │   └── screens/gate_screen.dart  # Blocking auth + location splash
    ├── dashboard/
    │   ├── providers/
    │   │   └── moto_provider.dart    # RideStatsNotifier, IgnitionNotifier, ahmedabadTemp
    │   └── screens/
    │       └── dashboard_screen.dart # 3D bike, stats, ignition button
    ├── tracking/
    │   ├── providers/
    │   │   └── tracking_provider.dart # GPS stream, polyline accumulation
    │   └── screens/
    │       └── tracking_screen.dart  # flutter_map + heat banner + FAB
    └── settings/
        └── screens/
            └── settings_screen.dart  # Language + theme toggles
```

---

## 🔄 App Flow

```
Cold Launch
    │
    ▼
GateScreen
    ├── [1] Biometric / PIN auth  ──── fail ──▶ Error + Retry button
    │         ✓
    ├── [2] GPS permission + getCurrentPosition  ──── fail ──▶ Error + Retry button
    │         ✓
    └── Fade transition (600ms)
            │
            ▼
    DashboardScreen
            │
            ▼ (Ignition button — HapticFeedback + OpenContainer)
    TrackingScreen  (map pre-centered on real GPS position)
            │
            ▼ (Settings icon in AppBar)
    SettingsScreen  (language + theme)
```

---

## 🧠 State Management

All providers use `@riverpod` annotations with code generation.

| Provider | Type | Responsibility |
|---|---|---|
| `AppGateNotifier` | `Notifier<AppGateState>` | Sequences biometric auth → GPS fetch |
| `ThemeNotifier` | `Notifier<ThemeMode>` | Dark / Light toggle |
| `LocaleNotifier` | `Notifier<Locale>` | EN / HI runtime switch |
| `RideStatsNotifier` | `Notifier<RideStats>` | Distance, fuel wallet, daily goal |
| `IgnitionNotifier` | `Notifier<bool>` | Ignition on/off state |
| `TrackingNotifier` | `Notifier<TrackingState>` | GPS stream, polyline points |
| `ahmedabadTemp` | `FutureProvider<double>` | Open-Meteo temperature fetch |

---

## 📦 Dependencies

### Runtime

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management |
| `riverpod_annotation` | ^2.6.1 | `@riverpod` annotations |
| `flutter_map` | ^7.0.2 | OpenStreetMap tiles |
| `latlong2` | ^0.9.1 | Lat/Lng coordinates |
| `geolocator` | ^13.0.2 | GPS stream + permissions |
| `flutter_3d_controller` | ^2.3.0 | Interactive `.glb` 3D viewer |
| `animations` | ^2.0.11 | `OpenContainer` transition |
| `local_auth` | ^2.3.0 | Biometric / PIN authentication |
| `easy_localization` | ^3.0.7 | EN / HI localization |
| `http` | ^1.2.2 | Open-Meteo weather API |

### Dev

| Package | Purpose |
|---|---|
| `riverpod_generator` | Generates `.g.dart` from `@riverpod` |
| `build_runner` | Code generation runner |
| `custom_lint` + `riverpod_lint` | Riverpod-aware lint rules |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.10.7`
- Dart SDK `^3.10.7`
- A physical device or emulator with biometric support (for full gate flow)

### 1. Clone & install

```bash
git clone https://github.com/<your-username>/motostack.git
cd motostack
flutter pub get
```

### 2. Generate Riverpod code

```bash
dart run build_runner build --delete-conflicting-outputs
```

> Run this every time you add or modify a `@riverpod` provider.

### 3. Add your assets

```
assets/
├── models/
│   └── meteor.glb        ← Place your Meteor 350 .glb model here
└── images/
    └── *.png / *.jpg     ← Any splash or UI images
```

### 4. Run

```bash
flutter run
```

---

## 🌐 Localization

Translation files live in `assets/translations/`:

| File | Language |
|---|---|
| `en.json` | English |
| `hi.json` | हिंदी (Hindi) |

To add a new language:
1. Create `assets/translations/<code>.json` mirroring the key structure of `en.json`
2. Add `Locale('<code>')` to `supportedLocales` in `main.dart` and `EasyLocalization`
3. Run `flutter pub get`

All strings use named-argument interpolation where needed:

```json
"daily_goal": "Daily Goal  {percent}%  (12 km)"
```

```dart
'dashboard.daily_goal'.tr(namedArgs: {'percent': '85'})
```

---

## 📍 Permissions

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS (`Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MotoStack needs location to track your ride.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>MotoStack needs location to track your ride in the background.</string>
<key>NSFaceIDUsageDescription</key>
<string>MotoStack uses Face ID to secure your ride data.</string>
```

---

## ⛽ Fuel Wallet Logic

Based on real Meteor 350 economics:

```
Mileage  : ~35 km/l
Petrol   : ~₹106/l  (Ahmedabad, 2024)
Cost/km  : ₹106 ÷ 35 = ₹3.03/km
Daily    : 12 km × ₹3.03 = ~₹36.36/day
```

The wallet starts at ₹500 and auto-deducts as you ride. Top up via `RideStatsNotifier.topUpFuel(amount)`.

---

## 🌡️ Ahmedabad Heat Warning

Uses the [Open-Meteo](https://open-meteo.com/) free API — **no API key required**.

```
Endpoint: https://api.open-meteo.com/v1/forecast
Params  : latitude=23.0225 & longitude=72.5714 & current_weather=true
Trigger : temperature > 40°C → red banner on tracking screen
Fallback: returns mock 42.0°C if the request fails (always shows in dev)
```

---

## 🛠️ Development Commands

```bash
# Install dependencies
flutter pub get

# Generate Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on save)
dart run build_runner watch --delete-conflicting-outputs

# Analyze
flutter analyze

# Run on device
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## 📁 Asset Structure

```
assets/
├── models/
│   └── meteor.glb          # Royal Enfield Meteor 350 3D model
├── images/
│   └── (screenshots, icons)
└── translations/
    ├── en.json             # English strings
    └── hi.json             # Hindi strings
```

---

## 👤 Author

**Senior Flutter Developer**
📍 Ahmedabad, Gujarat, India
🏍️ Royal Enfield Meteor 350 Supernova

---

## 📄 License

This project is private and not licensed for public distribution.
