# Compiles the FusionFix shader fixes in shaders/fixedshaders into
# data/update/common/shaders. The unmodified originals are in the separate
# MaxPayne3.FusionShaders repository and are not compiled here.
param(
    [switch]$Verify,
    [switch]$NoWarm
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'data\update\common\shaders'
$source = Join-Path $root 'shaders\fixedshaders'
$cache = Join-Path $root 'build\shadertool\hlsl-cache'

$tool = Join-Path $root 'bin\tools\mp3shadertool.exe'
if (-not (Test-Path $tool)) { $tool = Join-Path $root 'build\shadertool\bin\mp3shadertool.exe' }
if (-not (Test-Path $tool)) { throw "mp3shadertool.exe not found; build the ShaderTool project first (premake5.bat then msbuild build\ShaderTool.vcxproj)" }

Write-Output "mp3shadertool: $tool"
Write-Output "source: $source"
Write-Output "output: $out"
Write-Output "cache: $cache"

$warm = -not $NoWarm
if ($warm -and (Test-Path $cache) -and @(Get-ChildItem $cache -Filter '*.cso' -ErrorAction SilentlyContinue).Count -gt 0) {
    $warm = $false
}
if ($warm) {
    & $tool warm-hlsl $source --hlsl-cache $cache
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Remove-Item -Recurse -Force $out -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $out | Out-Null
& $tool build-tree $source $out --hlsl-cache $cache
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$files = @(Get-ChildItem -Recurse -File $out -Filter '*.fxc')
$bytes = ($files | Measure-Object Length -Sum).Sum
Write-Output ('built {0} shader containers ({1:N1} MB)' -f $files.Count, ($bytes / 1MB))

if ($Verify) {
    $temp = Join-Path $root 'build\shadertool\verify-output'
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
    & $tool build-tree $source $temp --hlsl-cache $cache
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $tempManifest = Join-Path $root 'build\shadertool\verify-temp.txt'
    $outManifest = Join-Path $root 'build\shadertool\verify-data.txt'
    & $tool manifest $temp $tempManifest
    & $tool manifest $out $outManifest
    if (Compare-Object @(Get-Content $tempManifest) @(Get-Content $outManifest)) { throw 'verify: generated shaders differ from data/update/common/shaders' }
    Remove-Item -Recurse -Force $temp
    Remove-Item -Force $tempManifest, $outManifest -ErrorAction SilentlyContinue
    Write-Output 'verify: every generated shader matches data/update/common/shaders'
}

exit 0