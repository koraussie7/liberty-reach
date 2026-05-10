# LLaVA Multimodal Model Downloader
# Downloads LLaVA 1.6 Mistral 7B (vision-language model)

$ErrorActionPreference = "Continue"
$modelDir = Join-Path (Split-Path -Parent $PSScriptRoot) "localai\models"
$modelDir = [System.IO.Path]::GetFullPath($modelDir)

if (-not (Test-Path $modelDir)) {
    New-Item -ItemType Directory -Path $modelDir -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LLaVA Multimodal Model Downloader" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$files = @(
    @{
        Name = "llava-v1.6-mistral-7b-Q4_K_M.gguf"
        Url = "https://huggingface.co/mys/ggml_llava-v1.6-mistral-7b/resolve/main/llava-v1.6-mistral-7b-Q4_K_M.gguf"
        Size = "4.37 GB"
    },
    @{
        Name = "llava-v1.6-mistral-7b-mmproj-f32.gguf"
        Url = "https://huggingface.co/mys/ggml_llava-v1.6-mistral-7b/resolve/main/mmproj-model-f16.gguf"
        Size = "1.2 GB"
    }
)

foreach ($file in $files) {
    $path = Join-Path $modelDir $file.Name
    if (Test-Path $path) {
        Write-Host "[OK] $($file.Name) already exists" -ForegroundColor Green
        continue
    }

    Write-Host "[DL] Downloading $($file.Name) ($($file.Size))..." -ForegroundColor Yellow
    Write-Host "     $($file.Url)" -ForegroundColor Gray

    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFileAsync($file.Url, $path)

        $lastUpdate = 0
        while ($wc.IsBusy) {
            Start-Sleep -Milliseconds 500
            if ((Get-Date).Second -ne $lastUpdate -and (Test-Path $path)) {
                $size = (Get-Item $path).Length
                $mb = [math]::Round($size / 1MB)
                Write-Host "`r  Downloaded: ${mb} MB" -NoNewline
                $lastUpdate = (Get-Date).Second
            }
        }
        Write-Host "`r  [OK] $($file.Name) downloaded" -ForegroundColor Green
    } catch {
        Write-Host "`r  [FAIL] Download failed: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Done! Models saved to: $modelDir" -ForegroundColor Cyan
Write-Host "  Restart LocalAI to load the new model" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
