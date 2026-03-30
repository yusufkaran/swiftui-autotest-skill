---
argument-hint: [--flow=<name>] [--screen=<ViewName>] [--device=<name>] [--scheme=<name>] [--states] [--screenshot-all] [--performance]
description: iOS/SwiftUI uygulamasini derle, simulator'da ac ve test et. "uygulamayi test et", "simulatorde calistir", "UI test", "flow test", "ekranlari kontrol et", "build and test", "crash var mi bak" gibi isteklerde tetiklenir.
---

# Claude Command: iOS Test

Bu komut iOS/SwiftUI uygulamasini derleyip simulator'da acarak computer use ile gorsel test yapar.

## Usage

```
/ios-test
/ios-test --flow=onboarding
/ios-test --screen=LoginView
/ios-test --device="iPhone 16 Pro"
/ios-test --scheme=MyApp
/ios-test --states
/ios-test --screenshot-all
/ios-test --flow=checkout --states --screenshot-all
```

## Command Options

- `--flow=<name>`: Belirli bir kullanici akisini test et (ornegin: onboarding, login, checkout)
- `--screen=<ViewName>`: Sadece belirli bir ekrani test et
- `--device=<name>`: Simulator cihazi belirt (ornegin: "iPhone 16 Pro", "iPhone SE")
- `--scheme=<name>`: Xcode scheme belirt
- `--states`: Empty, error ve loading state'lerini launch argument'lari ile test et
- `--screenshot-all`: Her adimda screenshot al
- `--performance`: Her ekranda RAM olcumu ve memory leak kontrolu yap (varsayilan testte YAPILMAZ)

## What This Command Does

### Phase 1: Project Discovery

1. Calisma dizininde `.xcodeproj` veya `.xcworkspace` dosyasini bul
   - `.xcworkspace` varsa onu tercih et (CocoaPods/SPM workspace)
   - Birden fazla varsa kullaniciya sor
   - Hicbiri yoksa hata ver ve dur

2. Mevcut scheme'leri listele:
   ```bash
   xcodebuild -list -workspace MyApp.xcworkspace
   ```
   - `--scheme` verilmisse onu kullan
   - Verilmemisse ve tek scheme varsa onu kullan
   - Birden fazla varsa kullaniciya sor

### Phase 2: Simulator Selection

**ONEMLI: Simulator secimi build'den once yapilmalidir. Build komutu secilen cihaz ismini kullanir.**

1. `--device` argumani verildiyse:
   - O cihazi bul: `xcrun simctl list devices --json`
   - Bulamazsa mevcut cihazlari listele ve kullaniciya sor

2. `--device` verilmediyse:
   ```bash
   xcrun simctl list devices booted --json
   ```

   - **Hic booted simulator yoksa:**
     Mevcut cihazlari listele:
     ```bash
     xcrun simctl list devices available --json
     ```
     En uygun iPhone'u oner, kullaniciya "Bu cihazda test koşayım mı?" diye sor.
     Onaylarsa boot et:
     ```bash
     xcrun simctl boot <device-udid>
     open -a Simulator
     ```

   - **Tek booted simulator varsa:**
     Direkt onu kullan, soru sorma.

   - **Birden fazla booted simulator varsa:**
     Listeyi goster, kullaniciya hangisini kullanacagini sor.

### Phase 3: Accessibility Check (ZORUNLU — ATLANMAMALI)

**Bu adim ZORUNLUDUR. Build'den ONCE calistirilir. Bu adimi ASLA atlama.**

1. Projedeki SwiftUI dosyalarini tara — `*.swift` dosyalarinda `struct` ... `: View` pattern'i ara
2. Bu dosyalarda su interactive elemanlari say: `Button`, `TextField`, `SecureField`, `Toggle`, `Slider`, `Picker`, `DatePicker`, `NavigationLink`, `Image`, `.onTapGesture`
3. Bu elemanlarin kacinda `.accessibilityIdentifier()` oldugunu kontrol et
4. **KULLANICIYA MUTLAKA SOR (bu soru atlanamaz):**

```
📋 Accessibility Scan Sonucu:
   Toplam interactive eleman: XX
   Identifier mevcut: XX
   Identifier eksik: XX

⚠️ Identifier'lar test sirasinda elemanlari daha guvenilir bulmami saglar.

Simdi /add-accessibility calistirip identifier'lari ekleyeyim mi?
  → Evet: identifier'lari ekler, sonra build alip teste devam eder
  → Hayir: direkt build alip koordinat bazli test yaparim (daha yavas ve kirilgan olabilir)
```

5. **Kullanicinin cevabini BEKLE.** Cevap almadan devam etme.
6. Kullanici evet derse → `/add-accessibility` skill'indeki tum adimlari calistir (scan, generate, apply), sonra Phase 4 (Build) ile devam et
7. Kullanici hayir derse → direkt Phase 4 (Build) ile devam et

### Phase 4: Build

1. Secilen cihaz ismiyle build et:
   ```bash
   xcodebuild build \
     -workspace MyApp.xcworkspace \
     -scheme MyApp \
     -destination 'platform=iOS Simulator,name=<SECILEN_CIHAZ>' \
     -derivedDataPath ./DerivedData \
     2>&1
   ```
   **ASLA sabit bir cihaz ismi hardcode etme. Her zaman Phase 2'de secilen cihazi kullan.**

2. Build basarisiz olursa:
   - Hata mesajlarini analiz et
   - Duzeltme onerileri sun
   - DUR — build basarisiz iken test etmeye calisma

3. Build uyarilarini da raporla (ama durma)

### Phase 5: Install & Launch

1. Build edilen .app dosyasini bul:
   ```bash
   find ./DerivedData -name "*.app" -path "*/Debug-iphonesimulator/*" | head -1
   ```

2. Bundle identifier'i bul:
   ```bash
   plutil -p /path/to/MyApp.app/Info.plist | grep CFBundleIdentifier
   ```

3. Simulator'a yukle ve baslat:
   ```bash
   xcrun simctl install booted /path/to/MyApp.app
   xcrun simctl launch booted <BUNDLE_ID>
   ```

### Phase 6: Computer Use ile Test

**ONEMLI: Bu asamada computer use (MCP server) gereklidir.**

Eger computer use etkin degilse kullaniciya soyle:
```
Computer use etkin degil. Test icin gerekli.
/mcp yazarak computer-use server'ini etkinlestirin.
```

#### Default Test (argumansiz)

Uygulamanin tum ana ekranlarini kesfet ve test et:

1. **TabView varsa** → her tab'a tikla, her ekrani incele
2. **NavigationStack varsa** → her navigasyon linkine tikla, geri don
3. **Her ekranda** kontrol et:
   - Ekran duzenli render ediliyor mu? (bos alan, tasma, ustuste binme)
   - Butonlar tiklanabilir mi?
   - Scroll calisiyorsa icerik gorunuyor mu?
   - Metin okunabilir mi? (cok kucuk, kesilmis)
4. Her ekranin screenshot'ini al

#### `--flow=<name>` ile

Belirtilen kullanici akisini test et. Akis ismine gore davran:

- **onboarding**: Onboarding ekranlarini swipe ile ilerle, tum adimlari gecir, son adimda tamamla
- **login**: Email/sifre alanlarini doldur (test@example.com / Test1234), giris butonuna bas, sonraki ekrani dogrula
- **signup**: Kayit formunu doldur, tum alanlari gez, kayit butonuna bas
- **checkout**: Sepet ekranina git, odeme akisini tamamla
- **settings**: Ayarlar ekranina git, her toggle/slider'i dene, geri don
- Diger akislar icin: kullaniciya "Bu akis icin hangi adimlari izleyeyim?" diye sor

#### `--screen=<ViewName>` ile

Sadece belirtilen ekrani bul ve test et. O ekrana ulasabilmek icin gerekli navigasyonu yap.

### Phase 7: State Testing (`--states`)

Bu asama launch argument'lari ile farkli durumlari test eder.

1. **Kontrol et**: Uygulamada `CommandLine.arguments` veya `ProcessInfo.processInfo.arguments` kullanilarak state override destegi var mi?
   - SwiftUI dosyalarinda `--show-empty-state`, `--show-error-state`, `--show-loading-state` ara
   - `@AppStorage` veya `UserDefaults` ile debug flag'leri ara

2. **Yoksa** kullaniciya sor:
   ```
   Uygulamada state test destegi bulamadim. Su launch argument convention'ini
   eklememi ister misiniz?

   AppDelegate veya @main App struct'a #if DEBUG bloku eklenecek:
   - --show-empty-state
   - --show-error-state
   - --show-loading-state

   Bu sayede test sirasinda her state'i tetikleyebilirim.
   Ekleyeyim mi? (sadece DEBUG build'de aktif olacak)
   ```

3. **Eklendiyse veya zaten varsa** → her state icin uygulamayi yeniden baslat:
   ```bash
   xcrun simctl terminate booted <BUNDLE_ID>
   xcrun simctl launch booted <BUNDLE_ID> --show-empty-state
   ```

   Her state'de:
   - **Empty state**: Ekran anlamli bir mesaj gosteriyor mu? "Henuz icerik yok" gibi?
   - **Error state**: Hata mesaji acik mi? "Tekrar dene" butonu var mi?
   - **Loading state**: Loading indicator gorunuyor mu? UI kitlenmis gibi durmuyor degil mi?
   - Her state'in screenshot'ini al

### Phase 8: Crash Log Analysis

Test suresince ve sonrasinda crash kontrolu yap:

1. Simulator crash log'larini kontrol et:
   ```bash
   xcrun simctl spawn booted log show --predicate 'process == "MyApp" AND messageType == 21' --last 5m
   ```

2. Eger crash varsa:
   - Crash stack trace'ini analiz et
   - Hangi ekranda / aksiyonda olustugunu belirle
   - Ilgili kodu bul ve neden olabilecegini raporla

### Phase 9: Performance Analysis (`--performance`)

**SADECE `--performance` argumani verildiginde calis. Default testte bu asamayi ATLA.**

Bu asama her ekranda RAM kullanimi olcer ve memory leak kontrolu yapar.

#### Adimlar

1. **Uygulamanin PID'ini bul:**
   ```bash
   xcrun simctl spawn booted launchctl list | grep <BundleID>
   ```

2. **Baseline olcum al** (uygulama ilk acildiginda):
   ```bash
   footprint -all <PID>
   ```
   Ciktiyi parse et, toplam RAM degerini kaydet.

3. **Her ekran gecisinde:**
   - Ekrana gec (computer use ile)
   - 2 saniye bekle (render tamamlansin)
   - `footprint -all <PID>` ile RAM olc
   - Onceki ekranla farki hesapla

4. **Geri donuslerde leak kontrolu:**
   - Bir ekrana gir → RAM olc
   - Geri don → RAM olc
   - Fark 5MB'den fazlaysa → potansiyel leak olarak flag'le

5. **Test sonunda genel leak taramasi:**
   ```bash
   leaks <PID>
   ```
   Ciktida leak bulunursa:
   - Leak sayisi
   - Leak olan nesne turleri
   - Stack trace (varsa)

6. **Sonuclari kaydet:**
   ```
   📊 Performance Raporu
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Baseline (launch):       42 MB

   Ekran Gecisleri:
     HomeView:              45 MB (+3 MB)
     SettingsView:          52 MB (+7 MB)
     ProfileView:           68 MB (+16 MB) ⚠️
     → HomeView (geri):     61 MB (-7 MB, 16 MB geri verilmedi) ⚠️

   Memory Leaks:            2 adet
     - SettingsViewModel: 1 leak (closure retain cycle?)
     - ImageCache: 1 leak

   ⚠️ Yuksek RAM: ProfileView (+16 MB atlama)
   ⚠️ Potansiyel Leak: HomeView'a donuste 16 MB geri verilmedi
   ```

#### Onemli

- `footprint` ve `leaks` komutlari simulator process'ine erisim gerektirir
- Eger PID bulunamazsa kullaniciya bildir ve bu asamayi atla
- Sonuclari ana test raporuna dahil et (Phase 10)

### Phase 10: Test Report

Test tamamlandiginda ozet rapor goster:

```
🧪 iOS Test Raporu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Uygulama:    MyApp (com.example.MyApp)
Cihaz:       iPhone 16 Pro (iOS 18.2)
Scheme:      MyApp
Sure:        2dk 34sn

📱 Test Edilen Ekranlar: 8
  ✅ HomeView - OK
  ✅ ProfileView - OK
  ⚠️ SettingsView - Toggle "notifications" tiklanamiyor
  ✅ OnboardingStep1 - OK
  ✅ OnboardingStep2 - OK
  ✅ OnboardingStep3 - OK
  ❌ CheckoutView - Crash (force unwrap on nil)
  ✅ SearchView - OK

📸 Screenshots: 12 adet alinmis

🔴 Crash: 1
  CheckoutView.swift:42 - Force unwrap on nil optional

⚠️ UI Sorunlari: 1
  SettingsView - notifications toggle'a erisim sorunu

📊 State Test Sonuclari:
  ✅ Empty State - OK
  ⚠️ Error State - "Tekrar dene" butonu eksik
  ✅ Loading State - OK
```

## Important Rules

1. **Build basarisiz olursa ASLA test asamasina gecme**
2. **Computer use olmadan gorsel test yapamazsin** — kullaniciya etkinlestirmesini soyle
3. Simulator seciminde gereksiz soru sorma — tek booted varsa direkt kullan
4. Her hata ve uyariyi raporla ama ASLA kullanici sormadan kodu degistirme
5. Test sirasinda uygulamanin verilerini silme veya degistirme
6. `--states` kullanilmadan launch argument ekleme onerme — sadece `--states` verildiginde oner
7. Crash tespit edersen stack trace ile birlikte ilgili kaynak kodu da goster
8. Screenshot'lari mantikli isimlerle kaydet (ornegin: `test-home-dark-mode.png`)
9. Test bittikten sonra simulator'u KAPATMA — kullanici devam etmek isteyebilir
10. Her asamayi kullaniciya kisa bir durum mesaji ile bildir ("Build ediliyor...", "Simulator baslatiliyor..." vb.)
