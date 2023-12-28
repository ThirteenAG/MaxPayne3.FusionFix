copy bin\MaxPayne3.FusionFix.asi data\plugins\MaxPayne3.FusionFix.asi

call buildwtd.bat

7z a "MaxPayne3.FusionFix.zip" ".\data\*" ^
-xr!*\.gitkeep
