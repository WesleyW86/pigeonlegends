@echo off
echo ========================================
echo    Pigeon Legends - GitHub Upload
echo ========================================
echo.

REM Controleer of Git geïnstalleerd is
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is niet geïnstalleerd!
    echo Download Git van: https://git-scm.com/
    pause
    exit /b 1
)

echo Git gevonden! Initialiseren van repository...
echo.

REM Initialiseer Git repository (als nog niet gedaan)
if not exist .git (
    git init
    echo Repository geïnitialiseerd.
)

REM Voeg alle bestanden toe (behalve config.js en Keys.txt)
echo Bestanden toevoegen aan Git...
git add *.html
git add *.js
git add *.sql
git add *.png
git add .gitignore
git add README.md

REM Commit de wijzigingen
echo.
echo Wijzigingen committen...
git commit -m "Pigeon Legends v1.0 - Beveiligingsupdate en nieuwe features"

REM Vraag om remote repository
echo.
echo ========================================
echo    GitHub Repository Setup
echo ========================================
echo.
echo Voer je GitHub repository URL in:
echo Voorbeeld: https://github.com/WesleyW86/pigeonlegends.git
echo.
set /p repo_url="Repository URL: "

REM Voeg remote toe en push
echo.
echo Verbinden met GitHub...
git remote add origin %repo_url%
git branch -M main
git push -u origin main

echo.
echo ========================================
echo    Upload voltooid! 🎉
echo ========================================
echo.
echo Je project is nu live op GitHub!
echo Bezoek: %repo_url%
echo.
pause 