#requires -version 5.1
<#
╔══════════════════════════════════════════════════════════════╗
║  Liberty Reach - AI Server Setup (Windows)                 ║
║                                                            ║
║  Installs: Docker Desktop + LocalAI + Gemma + LLaVA        ║
║  Runs: LocalAI container with multimodal support            ║
╚══════════════════════════════════════════════════════════════╝
#>

$ErrorActionPreference = "Stop"
$PROJECT_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$LOG = Join-Path $PROJECT_ROOT "setup_server.log"

function Log   { param([string]$M) $t = Get-Date -Format HH:mm:ss; "$t $M" | Add-Content $LOG; Write-Host "$M" @Args }
function OK    { param([string]$M) Log "  [OK] $M" -ForegroundColor Green }
function FAIL  { param([string]$M) Log "  [FAIL] $M" -ForegroundColor Red; exit 1 }
function INFO  { param([string]$M) Log "  [..] $M" -ForegroundColor Cyan }
function STEP  { param([string]$M) Write-Host "`n>>> $M" -ForegroundColor Yellow }

Clear-Host
Write-Host @"

██╗     ██╗██████╗ ███████╗██████╗ ████████╗██╗   ██╗
██║     ██║██╔══██╗██╔════╝██╔══██╗╚══██╔══╝╚██╗ ██╔╝
██║     ██║██████╔╝█████╗  ██████╔╝   ██║    ╚████╔╝
██║     ██║██╔══██╗██╔══╝  ██╔══██╗   ██║     ╚██╔╝
███████╗██║██████╔╝███████╗██║  ██║   ██║      ██║
╚══════╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝      ╚═╝

"@ -ForegroundColor Yellow
Write-Host "  AI Server Installer  |  Gemma (text) + LLaVA (multimodal)" -ForegroundColor White
Write-Host "  Log: $LOG" -ForegroundColor Gray
Write-Host ""

# ═════════ Step 1: Admin check ═════════
STEP "Step 1/5: Checking Administrator privileges"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")
if (-not $isAdmin) {
    Log "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
OK "Administrator privileges confirmed"

# ═════════ Step 2: Docker ═════════════
STEP "Step 2/5: Installing Docker Desktop"
$dockerPath = (Get-Command docker -ErrorAction SilentlyContinue).Source
if (-not $dockerPath) {
    INFO "Docker not found. Installing via winget..."
    winget install Docker.DockerDesktop --accept-source-agreements 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        FAIL "Docker install failed. Download manually: https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    }
    OK "Docker Desktop installed"
    Log "  Please restart your computer, then run this script again." -ForegroundColor Yellow
    Log "  After restart, Docker will be available." -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit (restart required)..."
    exit
}
$dockerVer = docker --version 2>&1
OK "Docker: $dockerVer"

# ═════════ Step 3: Download models ═════
STEP "Step 3/5: Downloading AI models"
$modelDir = Join-Path $PROJECT_ROOT "localai\models"
$configDir = Join-Path $PROJECT_ROOT "localai\config"
New-Item -ItemType Directory -Path $modelDir -Force | Out-Null
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

# Gemma-2-2B (text model, ~1.5GB)
$gemmaPath = Join-Path $modelDir "gemma-2-2b-it-Q4_K_M.gguf"
if (-not (Test-Path $gemmaPath)) {
    INFO "Downloading Gemma-2-2B (~1.5GB)..."
    $url = "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
    Invoke-WebRequest -Uri $url -OutFile $gemmaPath -UseBasicParsing
    OK "Gemma-2-2B downloaded"
} else { OK "Gemma-2-2B already present" }

# LLaVA (multimodal model, ~5.5GB)
$llavaPath = Join-Path $modelDir "llava-v1.6-mistral-7b-Q4_K_M.gguf"
$mmprojPath = Join-Path $modelDir "llava-v1.6-mistral-7b-mmproj-f32.gguf"
if (-not (Test-Path $llavaPath)) {
    INFO "Downloading LLaVA-1.6 Mistral 7B (~4.4GB) - this will take a while..."
    $url1 = "https://huggingface.co/mys/ggml_llava-v1.6-mistral-7b/resolve/main/llava-v1.6-mistral-7b-Q4_K_M.gguf"
    Invoke-WebRequest -Uri $url1 -OutFile $llavaPath -UseBasicParsing
    OK "LLaVA model downloaded"
} else { OK "LLaVA model already present" }

if (-not (Test-Path $mmprojPath)) {
    INFO "Downloading LLaVA mmproj (~1.2GB)..."
    $url2 = "https://huggingface.co/mys/ggml_llava-v1.6-mistral-7b/resolve/main/mmproj-model-f16.gguf"
    Invoke-WebRequest -Uri $url2 -OutFile $mmprojPath -UseBasicParsing
    OK "LLaVA mmproj downloaded"
} else { OK "LLaVA mmproj already present" }

# ═════════ Step 4: Config files ════════
STEP "Step 4/5: Creating LocalAI config files"

# Gemma config
@gc @"
name: gemma-2-2b-it
backend: llama
parameters:
  model: /models/gemma-2-2b-it-Q4_K_M.gguf
  temperature: 0.7
  top_k: 40
  top_p: 0.9
  context_size: 4096
  threads: 4
  f16: true
"@ | Out-File -FilePath (Join-Path $configDir "gemma.yaml") -Encoding ASCII

# LLaVA config
@gc @"
name: llava-1.6
backend: llama
parameters:
  model: /models/llava-v1.6-mistral-7b-Q4_K_M.gguf
  mmproj: /models/llava-v1.6-mistral-7b-mmproj-f32.gguf
  temperature: 0.7
  top_k: 40
  top_p: 0.9
  context_size: 4096
  threads: 4
  f16: true
"@ | Out-File -FilePath (Join-Path $configDir "llava.yaml") -Encoding ASCII

OK "Config files created"

# ═════════ Step 5: Start LocalAI ═══════
STEP "Step 5/5: Starting LocalAI"

# Kill existing container
docker stop liberty-localai 2>$null; docker rm liberty-localai 2>$null

INFO "Starting LocalAI container (Gemma + LLaVA)..."
docker run -d --name liberty-localai `
  -p 8080:8080 `
  -v "$modelDir`:/models" `
  -v "$configDir`:/config" `
  --restart unless-stopped `
  localai/localai:latest

if ($LASTEXITCODE -ne 0) { FAIL "Failed to start LocalAI" }

# Wait for it to be ready
INFO "Waiting for LocalAI to start (may take 1-2 minutes)..."
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:8080/healthz" -TimeoutSec 2 -ErrorAction Stop
        if ($r -eq "OK" -or $r -eq "ok" -or $r -eq $true) { $ready = $true; break }
    } catch {}
    Write-Host "`r  Waiting... $($i*2)s" -NoNewline
    Start-Sleep 2
}
Write-Host ""

if (-not $ready) { FAIL "LocalAI did not become ready in time. Check: docker logs liberty-localai" }

OK "LocalAI is running!"

# Show loaded models
Start-Sleep 3
try {
    $models = Invoke-RestMethod -Uri "http://localhost:8080/v1/models" -TimeoutSec 5
    Write-Host "`n  Loaded models:" -ForegroundColor Cyan
    $models | ConvertTo-Json -Depth 1
} catch { INFO "Could not list models (container may still be loading)" }

# ═════════ DONE ════════════
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║  AI Server is ready!                                        ║
║                                                            ║
║  LocalAI: http://localhost:8080                             ║
║  Models:  gemma-2-2b-it (text)                             ║
║           llava-1.6 (multimodal: text + image)              ║
║                                                            ║
║  Test:    curl http://localhost:8080/v1/models              ║
║  Logs:    docker logs liberty-localai -f                    ║
╚══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

OK "Setup complete!"
