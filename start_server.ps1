param(
    [string]$Identity = "liberty-server",
    [int]$Port = 8000
)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Binary = Join-Path $ProjectRoot "target\release\liberty-reach.exe"
$LogDir = Join-Path $ProjectRoot "logs"
$LogFile = Join-Path $LogDir "server.log"

# Create logs directory
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# Set MSVC environment
$msvcPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64"
$cargoBin = "$env:USERPROFILE\.cargo\bin"
$env:Path = "$msvcPath;$cargoBin;$env:Path"
$env:Path = ($env:Path.Split(';') | Where-Object { $_ -notlike '*Visual Studio\18*' }) -join ';'
$winKit = "C:\Program Files (x86)\Windows Kits\10"
$sdkVer = "10.0.26100.0"
$msvcVer = "14.44.35207"
$msvcRoot = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\$msvcVer"
$env:INCLUDE = "$msvcRoot\include;$winKit\Include\$sdkVer\ucrt;$winKit\Include\$sdkVer\um;$winKit\Include\$sdkVer\shared"
$env:LIB = "$msvcRoot\lib\x64;$winKit\Lib\$sdkVer\ucrt\x64;$winKit\Lib\$sdkVer\um\x64"

Write-Host "=== Liberty Reach Server ===" -ForegroundColor Cyan
Write-Host "Identity: $Identity"
Write-Host "Port: $Port"
Write-Host "Binary: $Binary"
Write-Host "Log: $LogFile"
Write-Host ""

# Load .env.local
$envFile = Join-Path $ProjectRoot ".env.local"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value -ErrorAction SilentlyContinue
        }
    }
}

# Start the server
Write-Host "Starting server..." -ForegroundColor Yellow
$startTime = Get-Date
$process = Start-Process -FilePath $Binary `
    -ArgumentList "--identity", $Identity, "--port", $Port.ToString(), "--storage", "sqlite" `
    -WorkingDirectory $ProjectRoot `
    -NoNewWindow -PassThru -RedirectStandardOutput $LogFile -RedirectStandardError "$LogFile.err"

Write-Host ""
Write-Host "[OK] Server started (PID: $($process.Id))" -ForegroundColor Green
Write-Host "     Listening on port $Port"
Write-Host "     Log: $LogFile"

# Wait briefly and check
Start-Sleep 3
if (-not $process.HasExited) {
    Write-Host "[OK] Server is running" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Server exited immediately. Check logs." -ForegroundColor Red
    Get-Content $LogFile -Tail 10
}

return $process.Id
