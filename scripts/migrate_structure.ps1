<#
╔══════════════════════════════════════════════════════════════╗
║  Liberty Reach - Project Structure Migration Script         ║
║  Clean Architecture: flutter_app + rust_core + models/docs  ║
╚══════════════════════════════════════════════════════════════╝
#>
$ROOT = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ROOT

function Log   { param([string]$M) Write-Host "  [..] $M" -ForegroundColor Cyan }
function OK    { param([string]$M) Write-Host "  [OK] $M" -ForegroundColor Green }
function WARN  { param([string]$M) Write-Host "  [!!] $M" -ForegroundColor Yellow }
function STEP  { param([string]$M) Write-Host "`n>>> $M" -ForegroundColor Yellow }

# ═══════════════════════════════════════════
# Step 1: Create target directories
# ═══════════════════════════════════════════
STEP "Step 1: Creating target directories"
$dirs = @(
    "rust_core\src\ai",
    "rust_core\src\p2p",
    "rust_core\src\crypto",
    "rust_core\src\storage",
    "rust_core\src\api",
    "rust_core\src\blockchain",
    "rust_core\src\reward",
    "rust_core\src\bridge",
    "docker\nginx",
    "models\tflite",
    "models\cheetah",
    "models\localai",
    "docs",
    "assets\icons",
    "assets\fonts",
    "flutter_app\lib\features\chat",
    "flutter_app\lib\features\loops",
    "flutter_app\lib\features\voice",
    "flutter_app\lib\features\ai_agents",
    "flutter_app\lib\features\reward",
    "flutter_app\lib\features\profile",
    "flutter_app\lib\shared\widgets",
    "flutter_app\lib\shared\services",
    "flutter_app\lib\shared\models",
    "flutter_app\lib\core\theme",
    "flutter_app\lib\core\constants"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}
OK "Target directories created"

# ═══════════════════════════════════════════
# Step 2: Migrate root Rust source -> rust_core/
# ═══════════════════════════════════════════
STEP "Step 2: Migrating root Rust source to rust_core/"
if (Test-Path "src") {
    Copy-Item "src\*" "rust_core\src\" -Recurse -Force
    OK "src/ -> rust_core/src/"
}
if (Test-Path "Cargo.toml") {
    Copy-Item "Cargo.toml" "rust_core\Cargo.toml" -Force
    OK "Cargo.toml -> rust_core/"
}
if (Test-Path "Cargo.lock") {
    Copy-Item "Cargo.lock" "rust_core\Cargo.lock" -Force
    OK "Cargo.lock -> rust_core/"
}

# ═══════════════════════════════════════════
# Step 3: Migrate Flutter Rust bridge -> rust_core/
# ═══════════════════════════════════════════
STEP "Step 3: Migrating flutter_rust_bridge to rust_core/"
if (Test-Path "flutter_app\rust") {
    # Merge flutter_app/rust/src/api/ into rust_core/src/api/
    if (Test-Path "flutter_app\rust\src\api") {
        Copy-Item "flutter_app\rust\src\api\*" "rust_core\src\api\" -Recurse -Force
        OK "flutter_app/rust/src/api/ -> rust_core/src/api/"
    }
    # Merge lib.rs
    if (Test-Path "flutter_app\rust\src\lib.rs") {
        Copy-Item "flutter_app\rust\src\lib.rs" "rust_core\src\lib.rs" -Force
        OK "flutter_app/rust/src/lib.rs -> rust_core/src/lib.rs"
    }
    # Merge bridge-specific modules (ai, crypto, p2p, storage from flutter_app/rust)
    @("ai", "crypto", "p2p", "storage") | ForEach-Object {
        $srcPath = "flutter_app\rust\src\$_"
        if (Test-Path $srcPath) {
            Copy-Item "$srcPath\*" "rust_core\src\$_\" -Recurse -Force
            OK "flutter_app/rust/src/$_/ -> rust_core/src/$_/"
        }
    }
    WARN "flutter_app/rust/ kept as backup. Remove manually after verification."
}

# ═══════════════════════════════════════════
# Step 4: Update flutter_rust_bridge.yaml
# ═══════════════════════════════════════════
STEP "Step 4: Updating flutter_rust_bridge.yaml"
$frbYaml = "flutter_app\flutter_rust_bridge.yaml"
if (Test-Path $frbYaml) {
    $content = @"
rust_input: ../rust_core/src/api/
rust_root: ../rust_core/
dart_output: lib/src/rust/
"@
    Set-Content -Path $frbYaml -Value $content -Encoding ASCII
    OK "flutter_rust_bridge.yaml updated to point to ../rust_core/"
}

# ═══════════════════════════════════════════
# Step 5: Merge Cargo.toml (root + flutter_app/rust)
# ═══════════════════════════════════════════
STEP "Step 5: Creating merged Cargo.toml (binary + library)"
$mergedCargo = @'
[package]
name = "liberty-reach"
version = "0.2.0"
edition = "2021"

[[bin]]
name = "liberty-reach"
path = "src/main.rs"

[lib]
name = "liberty_reach_core"
crate-type = ["cdylib", "staticlib", "lib"]
path = "src/lib.rs"

[dependencies]
flutter_rust_bridge = "=2.0.0"
libp2p = { version = "0.54", features = ["gossipsub", "noise", "yamux", "mdns", "kad", "tcp", "quic", "tokio", "macros"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
reqwest = { version = "0.12", features = ["json"] }
rusqlite = { version = "0.31", features = ["bundled"] }
chrono = { version = "0.4", features = ["serde"] }
flume = "0.11"
futures = "0.3"
tracing = "0.1"
tracing-subscriber = "0.3"
anyhow = "1"
clap = { version = "4", features = ["derive"] }
directories = "5"
uuid = { version = "1", features = ["v4"] }
base64 = "0.22"
ed25519-dalek = "2"
rand = "0.8"
blake3 = "1.5"
once_cell = "1"
'@
Set-Content -Path "rust_core\Cargo.toml" -Value $mergedCargo -Encoding ASCII
OK "rust_core/Cargo.toml created (binary + library dual output)"

# ═══════════════════════════════════════════
# Step 6: Migrate Docker files
# ═══════════════════════════════════════════
STEP "Step 6: Moving Docker files to docker/"
$dockerFiles = @("Dockerfile", "docker-compose.yml", "liberty-nginx.conf")
foreach ($f in $dockerFiles) {
    if (Test-Path $f) {
        Copy-Item $f "docker\$f" -Force
        OK "$f -> docker/$f"
    }
}

# ═══════════════════════════════════════════
# Step 7: Move LocalAI configs to models/localai
# ═══════════════════════════════════════════
STEP "Step 7: Moving model configs"
if (Test-Path "localai\config") {
    Copy-Item "localai\config\*" "models\localai\" -Recurse -Force
    OK "localai/config/ -> models/localai/"
}

# ═══════════════════════════════════════════
# Step 8: Move scripts
# ═══════════════════════════════════════════
STEP "Step 8: Organizing scripts"
$scriptFiles = @("build_release.ps1", "start_server.ps1", "setup.ps1", "deploy.ps1", "git_push.ps1")
foreach ($f in $scriptFiles) {
    if (Test-Path $f -and (Get-Item $f).Length -gt 0) {
        if (-not (Test-Path "scripts\$f")) {
            Move-Item $f "scripts\$f" -Force
            OK "$f -> scripts/$f"
        }
    }
}
# Move install scripts
$installScripts = @("install.bat", "setup_server.bat", "setup_server.ps1", "windows_install.ps1", "run.bat")
foreach ($f in $installScripts) {
    if (Test-Path $f -and (Get-Item $f).Length -gt 0) {
        if (-not (Test-Path "scripts\$f")) {
            Move-Item $f "scripts\$f" -Force
            OK "$f -> scripts/$f"
        }
    }
}

# ═══════════════════════════════════════════
# Step 9: Create placeholder files
# ═══════════════════════════════════════════
STEP "Step 9: Creating placeholder files for new structure"

# docs/
@"
# Architecture
- Rust Core: rust_core/src/
- Flutter App: flutter_app/lib/features/
- P2P: libp2p + Gossipsub
- Blockchain: Minima Tx-PoW
- AI: LocalAI + Gemma-2-2B + OpenMythos
"@ | Out-File "docs\architecture.md" -Encoding ASCII

@"
# Tokenomics: DADA Point
- Reward mechanism based on contribution
- Minima Tx-PoW for distribution
- Loops video watch rewards
"@ | Out-File "docs\tokenomics.md" -Encoding ASCII

"# Roadmap" | Out-File "docs\roadmap.md" -Encoding ASCII
"# Privacy & GDPR" | Out-File "docs\privacy.md" -Encoding ASCII

# assets/
"# Icons" | Out-File "assets\icons\.gitkeep" -Encoding ASCII
"# Fonts" | Out-File "assets\fonts\.gitkeep" -Encoding ASCII

# models/
"# TFLite model files" | Out-File "models\tflite\.gitkeep" -Encoding ASCII
"# Cheetah STT model files" | Out-File "models\cheetah\.gitkeep" -Encoding ASCII

OK "Placeholder files created"

# ═══════════════════════════════════════════
# Step 10: Create flutter_app/features/ stubs
# ═══════════════════════════════════════════
STEP "Step 10: Creating feature module stubs"

$features = @{
    "chat"      = "Chat feature - messaging UI, chat list, message bubbles";
    "loops"     = "Loops video ecosystem - watch, earn, AI insights";
    "voice"     = "Voice system - STT, TTS, voice circle UI";
    "ai_agents" = "AI Agent UI - Hermes, OpenMythos, OpenClaw interaction";
    "reward"    = "DADA Point reward - balance, history, earn screen";
    "profile"   = "User profile - settings, preferences, identity";
}

foreach ($feat in $features.Keys) {
    $desc = $features[$feat]
    $dir = "flutter_app\lib\features\$feat"
    @"
// $desc
// Feature module: $feat
"@ | Out-File "$dir\$feat.dart" -Encoding ASCII
    @"
/// Data layer for $feat feature
"@ | Out-File "$dir\data.dart" -Encoding ASCII
    @"
/// Presentation layer for $feat feature
"@ | Out-File "$dir\presentation.dart" -Encoding ASCII
    OK "flutter_app/lib/features/$feat/ created"
}

# shared stubs
@"
/// Shared widgets (reusable across features)
"@ | Out-File "flutter_app\lib\shared\widgets\shared_widgets.dart" -Encoding ASCII
@"
/// Shared services (api, db, etc.)
"@ | Out-File "flutter_app\lib\shared\services\shared_services.dart" -Encoding ASCII
@"
/// Shared data models
"@ | Out-File "flutter_app\lib\shared\models\shared_models.dart" -Encoding ASCII

# core stubs
@"
/// App theme (colors, typography, glassmorphism)
"@ | Out-File "flutter_app\lib\core\theme\app_theme.dart" -Encoding ASCII
@"
/// App constants (strings, dimensions, api endpoints)
"@ | Out-File "flutter_app\lib\core\constants\app_constants.dart" -Encoding ASCII

# ═══════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════
STEP "Migration Complete!"
Write-Host @"

  ╔══════════════════════════════════════════════════════════╗
  ║  New project structure is ready!                        ║
  ╚══════════════════════════════════════════════════════════╝

  Key changes:
  - rust_core/      : Unified Rust backend (binary + library)
  - flutter_app/    : Feature-first architecture
  - docker/         : Docker & Nginx configs
  - models/         : ML models (TFLite, Cheetah, LocalAI)
  - docs/           : Architecture & tokenomics docs
  - assets/         : Shared icons & fonts

  Remaining manual steps:
  1. flutter_app/rust/ kept as backup — remove after verifying build
  2. Update pubspec.yaml to point to new rust_core path
  3. Run: flutter_rust_bridge_codegen generate (in flutter_app/)
  4. Run: cd rust_core && cargo build --release

  Old files at root (src/, Cargo.toml, Dockerfile, etc.) still exist.
  Delete them after confirming the new structure works.

"@ -ForegroundColor Green
