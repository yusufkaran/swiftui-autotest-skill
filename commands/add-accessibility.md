---
argument-hint: [--dry-run] [--path=Sources/] [--verbose]
description: SwiftUI view'lara accessibility identifier ekle. "accessibility ekle", "identifier ekle", "test icin etiketle", "VoiceOver destegi ekle", "erisilebilirlik ekle" gibi isteklerde tetiklenir.
---

# Claude Command: Add Accessibility

Bu komut SwiftUI dosyalarini tarayarak eksik accessibility identifier'lari otomatik ekler ve Dynamic Type uyumsuzluklarini raporlar.

## Usage

```
/add-accessibility
/add-accessibility --dry-run
/add-accessibility --path=Sources/Features/Login
/add-accessibility --verbose
```

## Command Options

- `--dry-run`: Degisiklik yapma, sadece ne yapilacagini raporla
- `--path=<path>`: Sadece belirtilen dizini tara (varsayilan: tum SwiftUI dosyalari)
- `--verbose`: Her eklenen identifier'i detayli logla

## What This Command Does

### Phase 1: Scan & Analyze

1. Projedeki tum `*.swift` dosyalarini bul
2. SwiftUI view'leri iceren dosyalari filtrele (struct X: View, #Preview, vb.)
3. Her dosyada su elemanlari tespit et:
   - `Button` - butonlar
   - `TextField` ve `SecureField` - input alanlari
   - `Image` - gorseller
   - `Toggle` - toggle switch'ler
   - `Slider` - slider'lar
   - `Picker` - picker'lar
   - `DatePicker` - tarih seciciler
   - `NavigationLink` - navigasyon linkleri
   - `TabView` icindeki tab item'lar
   - `.onTapGesture` olan view'lar - tap gesture'lu elemanlar
   - `Link` - harici link'ler

4. Her eleman icin mevcut accessibility durumunu kontrol et:
   - `.accessibilityIdentifier()` var mi?
   - `.accessibilityLabel()` var mi?
   - Eger varsa → ATLA, dokunma

### Phase 2: Generate Identifiers

Naming convention: `{screen}-{type}-{name}`

**Screen ismi**: Dosya adindan turet
- `LoginView.swift` → `login`
- `OnboardingStepView.swift` → `onboarding-step`
- `HomeTabView.swift` → `home-tab`
- `View` suffix'ini kaldir, camelCase'i kebab-case'e cevir

**Type**: Eleman turune gore
| SwiftUI Element | Type |
|----------------|------|
| Button | `button` |
| TextField | `textfield` |
| SecureField | `securefield` |
| Image | `image` |
| Toggle | `toggle` |
| Slider | `slider` |
| Picker | `picker` |
| DatePicker | `datepicker` |
| NavigationLink | `navlink` |
| Link | `link` |
| .onTapGesture view | `tap` |
| TabView item | `tab` |

**Name**: Elemanin iceriginden turet
- `Button("Continue")` → `continue`
- `TextField("Email", ...)` → `email`
- `Image(systemName: "gear")` → `gear`
- `Image("hero-banner")` → `hero-banner`
- `Toggle("Notifications", ...)` → `notifications`
- Icerik yoksa veya karmasiksa → eleman sirasiyla numara ver (`button-1`, `button-2`)

**Ornek sonuclar:**
```
login-button-continue
login-textfield-email
login-securefield-password
onboarding-image-hero-banner
settings-toggle-notifications
home-tab-profile
```

### Phase 3: Apply Changes

Her eksik eleman icin `.accessibilityIdentifier("generated-id")` ekle:

```swift
// ONCE
Button("Continue") {
    viewModel.proceed()
}

// SONRA
Button("Continue") {
    viewModel.proceed()
}
.accessibilityIdentifier("login-button-continue")
```

**Image'lar icin** ek olarak `accessibilityLabel` da ekle (VoiceOver icin):

```swift
// ONCE
Image(systemName: "gear")

// SONRA
Image(systemName: "gear")
    .accessibilityIdentifier("settings-image-gear")
    .accessibilityLabel("Settings")
```

**onTapGesture view'lar icin** accessibility element olarak isaretle:

```swift
// ONCE
HStack {
    Image("avatar")
    Text(user.name)
}
.onTapGesture { showProfile() }

// SONRA
HStack {
    Image("avatar")
    Text(user.name)
}
.onTapGesture { showProfile() }
.accessibilityElement(children: .combine)
.accessibilityIdentifier("profile-tap-user-row")
.accessibilityAddTraits(.isButton)
```

### Phase 4: Dynamic Type Check

Text elemanlari icin Dynamic Type uyumunu kontrol et:

1. **Flag'le** (uyari olarak raporla, otomatik duzeltme YAPMA):
   - `Text` elemanlari `.lineLimit()` OLMADAN kullaniliyorsa ve uzun icerik olabilecekse
   - `Text` elemanlari `.minimumScaleFactor()` OLMADAN sabit alanlarda kullaniliyorsa
   - `.font(.system(size: XX))` ile hardcoded font size kullaniliyorsa (`.font(.title)` gibi dynamic font yerine)

2. **Rapor formati:**
```
⚠️ Dynamic Type Uyarilari:
  LoginView.swift:42 - Text("Welcome back...") → lineLimit veya minimumScaleFactor eksik
  LoginView.swift:58 - Text(...).font(.system(size: 14)) → Dynamic font kullanmayi dusunun (.body, .caption vb.)
  SettingsView.swift:23 - Text(longString) → lineLimit eksik, uzun metinlerde tasma riski
```

### Phase 5: Summary Report

Islem sonunda ozet rapor goster:

```
✅ Accessibility Scan Tamamlandi
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Taranan dosya:     24
Eleman bulundu:    87
Zaten mevcut:      31 (atlanildi)
Yeni eklenen:      56
  - Button:        18
  - TextField:      8
  - Image:         12
  - Toggle:         6
  - Diger:         12

⚠️ Dynamic Type Uyarilari: 7
  (detaylar yukarida)

Pattern: {screen}-{type}-{name}
```

## Important Rules

1. **ASLA mevcut accessibility modifier'lari degistirme veya silme**
2. **ASLA view'in islevselligini veya gorunumunu degistirme**
3. Sadece `.accessibilityIdentifier()`, `.accessibilityLabel()`, `.accessibilityElement()`, `.accessibilityAddTraits()` ekle
4. `#if DEBUG` blogu KULLANMA — identifier'lar production'da da olmali (gercek accessibility icin)
5. Eger bir identifier ismi uretmekte emin degilsen, `{screen}-{type}-{index}` formatini kullan ve verbose modda flag'le
6. Dynamic Type uyarilarini SADECE raporla, otomatik duzeltme yapma — kullanici kararina birak
7. `--dry-run` modunda hicbir dosyayi degistirme, sadece plan goster
8. Her dosyayi degistirdikten sonra compile check yap — syntax hatasi olusturursan geri al
