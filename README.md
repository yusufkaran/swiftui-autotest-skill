# iOS Tester Skill

Claude Code ile iOS/SwiftUI uygulamalarini otomatik test eden ve accessibility altyapisini hazirlayan skill seti.

Computer use ile simulator'da gorsel test yapar, memory leak arar, accessibility identifier'lari ekler — hepsi terminalden, tek komutla.

## Icerdigi Skill'ler

| Skill | Komut | Ne Yapar |
|-------|-------|----------|
| **iOS Test** | `/ios-test` | Build, simulator, computer use ile gorsel test, crash log, state testing, performance analizi |
| **Add Accessibility** | `/add-accessibility` | SwiftUI view'lara `{screen}-{type}-{name}` pattern'i ile accessibility identifier ekler |

## Kurulum

### Yontem 1: npx skills (onerilen)

```bash
npx skills add https://github.com/anthropics/ios-tester-skill
```

Kurulum sirasinda scope secmeniz istenir:

```
? Skill'i hangi kapsamda yuklemek istersiniz?

  1. User Scope (Kullanici)
     Tum projelerinizde gecerli olur.
     → ~/.claude/commands/ dizinine yuklenir

  2. Project Scope (Proje)
     Sadece bu repository icin gecerli.
     Projeyi ceken diger gelistiriciler de kullanabilir.
     → .claude/commands/ dizinine yuklenir ve git'e dahil edilir

  3. Local Scope (Yerel)
     Sadece bu projede, sadece bu bilgisayarda gecerli.
     → .claude/commands/ dizinine yuklenir ve .gitignore'a eklenir
```

### Yontem 2: Claude Code Plugin Marketplace

#### 1. Marketplace ekle

```bash
/plugin marketplace add anthropics/ios-tester-skill
```

#### 2. Scope secip kur

**User Scope** — tum projelerde gecerli:
```bash
/plugin install ios-tester --scope=user
```

**Project Scope** — sadece bu repo, takim arkadaslarin da kullanir:
```bash
/plugin install ios-tester --scope=project
```

**Local Scope** — sadece bu repo, sadece bu bilgisayar:
```bash
/plugin install ios-tester --scope=local
```

#### Project Scope icin `.claude/settings.json` yapilandirmasi

Projeyi ceken diger gelistiricilerin otomatik erisimi icin:

```json
{
  "enabledPlugins": {
    "ios-tester@ios-test": true,
    "ios-tester@add-accessibility": true
  },
  "extraKnownMarketplaces": {
    "ios-tester-skill": {
      "source": {
        "source": "github",
        "repo": "anthropics/ios-tester-skill"
      }
    }
  }
}
```

Takim uyeleriniz projeyi actiginda Claude Code skill'i kurmalarini ister.

### Yontem 3: Manuel kurulum

```bash
git clone https://github.com/anthropics/ios-tester-skill.git
```

Dosyalari scope'a gore kopyalayin:

| Scope | Hedef Dizin | Git'e Dahil |
|-------|-------------|-------------|
| User | `~/.claude/commands/` | Hayir |
| Project | `.claude/commands/` | Evet |
| Local | `.claude/commands/` + `.gitignore`'a ekle | Hayir |

```bash
# User scope
cp commands/*.md ~/.claude/commands/

# Project scope
mkdir -p .claude/commands
cp commands/*.md .claude/commands/

# Local scope
mkdir -p .claude/commands
cp commands/*.md .claude/commands/
echo ".claude/commands/ios-test.md" >> .gitignore
echo ".claude/commands/add-accessibility.md" >> .gitignore
```

## Kullanim

### /ios-test

Uygulamayi derler, simulator'da acar ve computer use ile gorsel test yapar.

```bash
# Tum ekranlari test et
/ios-test

# Belirli bir flow
/ios-test --flow=onboarding

# Belirli bir ekran
/ios-test --screen=LoginView

# Cihaz sec
/ios-test --device="iPhone 16"

# State testing (empty, error, loading)
/ios-test --states

# Performance analizi (RAM, memory leak)
/ios-test --performance

# Her adimda screenshot
/ios-test --screenshot-all

# Hepsini birden
/ios-test --flow=checkout --states --performance --screenshot-all
```

Dogal dil ile de calisir:
- "uygulamayi test et"
- "simulatorde calistir"
- "crash var mi bak"
- "ekranlari kontrol et"

### /add-accessibility

SwiftUI view'lara accessibility identifier ekler.

```bash
# Tum projeyi tara ve ekle
/add-accessibility

# Onizleme (degisiklik yapma)
/add-accessibility --dry-run

# Belirli klasor
/add-accessibility --path=Sources/Features/Login

# Detayli log
/add-accessibility --verbose
```

Dogal dil ile de calisir:
- "accessibility ekle"
- "identifier ekle"
- "VoiceOver destegi ekle"

#### Naming Convention

```
{screen}-{type}-{name}
```

| Ornek | Sonuc |
|-------|-------|
| `LoginView.swift` > `Button("Continue")` | `login-button-continue` |
| `LoginView.swift` > `TextField("Email")` | `login-textfield-email` |
| `SettingsView.swift` > `Toggle("Notifications")` | `settings-toggle-notifications` |
| `HomeView.swift` > `Image(systemName: "gear")` | `home-image-gear` |

## Gereksinimler

### /ios-test icin
- macOS
- Xcode + iOS Simulator
- Claude Code v2.1.85+ (computer use destegi)
- Pro veya Max plan (computer use icin)
- `computer-use` MCP server etkin (`/mcp` ile etkinlestir)

### /add-accessibility icin
- SwiftUI projesi (ek bagimliligi yok)

## Scope Rehberi

Hangi scope'u secmelisiniz?

| Durum | Onerilen Scope |
|-------|---------------|
| Sadece ben kullanacagim, tum projelerimde | **User** |
| Tum takim kullanacak, repo'ya dahil olsun | **Project** |
| Denemek istiyorum, repo'ya karismadan | **Local** |
| Acik kaynak proje, katkilcilar da kullansin | **Project** |

## Lisans

MIT
