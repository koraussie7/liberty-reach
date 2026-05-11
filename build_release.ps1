$msvcPath2022 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64"
$cargoBin = "$env:USERPROFILE\.cargo\bin"
$env:Path = "$msvcPath2022;$cargoBin;$env:Path"
$env:Path = ($env:Path.Split(';') | Where-Object { $_ -notlike '*Visual Studio\18*' }) -join ';'
$winKit = "C:\Program Files (x86)\Windows Kits\10"
$sdkVer = "10.0.26100.0"
$msvcVer = "14.44.35207"
$msvcRoot = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\$msvcVer"
$env:INCLUDE = "$msvcRoot\include;$winKit\Include\$sdkVer\ucrt;$winKit\Include\$sdkVer\um;$winKit\Include\$sdkVer\shared"
$env:LIB = "$msvcRoot\lib\x64;$winKit\Lib\$sdkVer\ucrt\x64;$winKit\Lib\$sdkVer\um\x64"

Write-Host "=== Building Liberty Reach ===" -ForegroundColor Cyan
Write-Host "Linker: $(Get-Command link.exe | Select-Object -ExpandProperty Source)"
Write-Host ""

cargo build --release 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Build complete!" -ForegroundColor Green
    $binary = "target\release\liberty-reach.exe"
    if (Test-Path $binary) {
        Write-Host "Binary: $((Get-Item $binary).FullName)" -ForegroundColor Cyan
    }
} else {
    Write-Host ""
    Write-Host "[FAIL] Build failed" -ForegroundColor Red
    exit 1
}
