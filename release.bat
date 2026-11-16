call tools\EmbedPDB\EmbedPDB.exe bin\MaxPayne3.FusionFix.asi

powershell -NoProfile -ExecutionPolicy Bypass -File "sign.ps1" -SearchPaths ".\bin\MaxPayne3.FusionFix.asi"

if not exist data\plugins mkdir data\plugins
copy bin\MaxPayne3.FusionFix.asi data\plugins\MaxPayne3.FusionFix.asi || exit /b 1
rem FusionFixHub.exe ships with the fix, at the game's root (updates, settings editor, DLAA/FSR). HUB_EXE picks it;
rem by default it is FusionFixHub.exe next to this script (the workflow downloads the signed release there).
if not defined HUB_EXE set "HUB_EXE=FusionFixHub.exe"
if exist "%HUB_EXE%" (
    copy /y "%HUB_EXE%" data\FusionFixHub.exe
) else if "%GITHUB_ACTIONS%"=="true" (
    echo WARNING: no FusionFixHub.exe ^(HUB_RELEASE_TOKEN not set^): the package is built without the hub
) else (
    echo ERROR: FusionFixHub.exe not found at "%HUB_EXE%". Put the signed FusionFixHub.exe next to release.bat or set HUB_EXE to its path.
    exit /b 1
)

call buildwtd.bat

if exist "MaxPayne3.FusionFix.zip" (
    del "MaxPayne3.FusionFix.zip" || exit /b 1
)
7z a "MaxPayne3.FusionFix.zip" ".\data\*" ^
-xr!*\.gitkeep
exit /b 0
