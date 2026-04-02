call tools\EmbedPDB\EmbedPDB.exe bin\MaxPayne3.FusionFix.asi

powershell -NoProfile -ExecutionPolicy Bypass -File "Sign.ps1" -SearchPaths ".\bin\MaxPayne3.FusionFix.asi"

copy bin\MaxPayne3.FusionFix.asi data\plugins\MaxPayne3.FusionFix.asi

call buildwtd.bat

7z a "MaxPayne3.FusionFix.zip" ".\data\*" ^
-xr!*\.gitkeep
