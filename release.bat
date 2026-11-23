call tools\EmbedPDB\EmbedPDB.exe bin\MaxPayne3.FusionFix.asi

powershell -NoProfile -ExecutionPolicy Bypass -File "sign.ps1" -SearchPaths ".\bin\MaxPayne3.FusionFix.asi"

if not exist data\plugins mkdir data\plugins
copy bin\MaxPayne3.FusionFix.asi data\plugins\MaxPayne3.FusionFix.asi || exit /b 1

call buildwtd.bat

if exist "MaxPayne3.FusionFix.zip" (
    del "MaxPayne3.FusionFix.zip" || exit /b 1
)
7z a "MaxPayne3.FusionFix.zip" ".\data\*" ^
-x!FusionFixHub.exe ^
-xr!*\.gitkeep
exit /b 0
