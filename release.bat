for /f "tokens=1,* delims=:" %%A in ('curl -ks https://api.github.com/repos/elishacloud/dxwrapper/releases/latest ^| find "browser_download_url"') do (
  echo.%%B | FIND /I "dxwrapper">Nul && echo.%%B | FIND /I "debug">Nul || (
    curl -o dxwrapper.zip -kL %%B
  )
)

7z e "dxwrapper.zip" "dxwrapper.asi" -o".\data\plugins" -y

call tools\EmbedPDB\EmbedPDB.exe bin\MaxPayne3.FusionFix.asi

powershell -NoProfile -ExecutionPolicy Bypass -File "Sign.ps1" -SearchPaths ".\bin\MaxPayne3.FusionFix.asi"

copy bin\MaxPayne3.FusionFix.asi data\plugins\MaxPayne3.FusionFix.asi

call buildwtd.bat

7z a "MaxPayne3.FusionFix.zip" ".\data\*" ^
-xr!*\.gitkeep
