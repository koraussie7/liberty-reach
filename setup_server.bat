@echo off
title Liberty Reach - AI Server Installer
cd /d "%~dp0"

echo ========================================
echo   Liberty Reach AI Server Installer
echo ========================================
echo.
echo  This will install:
echo    - Docker Desktop
echo    - Gemma-2-2B (text AI, ~1.5GB)
echo    - LLaVA 1.6 (multimodal AI, ~5.5GB)
echo    - LocalAI server (port 8080)
echo.
echo  Total download: ~7GB
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_server.ps1"
pause
