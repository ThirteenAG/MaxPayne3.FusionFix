@echo off
setlocal
if "%~1"=="" (
    echo Drag your extracted DDS folder onto this file.
    echo Or run: ScanDDS.cmd "D:\ExtractedTextures"
    pause
    exit /b 2
)
set "mipReport=%~1\MipReview-%RANDOM%-%RANDOM%"
python "%~dp0scan.py" "%~1" --output "%mipReport%"
if errorlevel 1 (
    echo Scan failed. Python, Pillow and NumPy are required.
    echo Install dependencies with: python -m pip install -r "%~dp0requirements.txt"
    pause
    exit /b 1
)
start "" "%mipReport%\index.html"
