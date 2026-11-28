@echo off
setlocal
if "%~1"=="" (
    echo Drag the game folder containing MaxPayne3.exe onto this file.
    echo See EXTRACT.md for archive-only extraction and inventory options.
    pause
    exit /b 2
)
if not exist "%~1\MaxPayne3.exe" (
    echo This is not the game folder containing MaxPayne3.exe.
    pause
    exit /b 2
)
set "textureOutput=%~1\ExtractedDDS-%RANDOM%-%RANDOM%"
echo Exporting original textures and mip chains to:
echo "%textureOutput%"
python "%~dp0extract.py" "%~1" --output "%textureOutput%"
if errorlevel 1 (
    echo Extraction did not finish cleanly. Review errors.csv and summary.json if created.
    pause
    exit /b 1
)
echo Extraction complete. Drag the output folder onto ScanDDS.cmd to review candidates.
start "" "%textureOutput%"
