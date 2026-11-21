# Rebuilds core/SX_COMMAND.gfx from the base minimap overlay and gfx/src/sx_engine.as.
# usage: .\gfx\build.ps1 -FFDec C:\path\to\ffdec-cli.jar   (or set $env:FFDEC)
param(
    [string]$FFDec = $env:FFDEC
)

$ErrorActionPreference = 'Stop'

if (-not $FFDec) {
    throw 'Pass -FFDec or set $env:FFDEC to the path of JPEXS ffdec-cli.jar'
}
if (-not (Test-Path $FFDec)) {
    throw "ffdec-cli.jar not found: $FFDec"
}
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw 'java was not found in the PATH, install Java 8 or newer'
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$base = Join-Path $root 'gfx\base\MINIMAP_LOADER.gfx'
$engine = Join-Path $root 'gfx\src\sx_engine.as'
$output = Join-Path $root 'core\SX_COMMAND.gfx'
$class = '__Packages\com\rockstargames\gtav\levelDesign\MINIMAP_LOADER.as'
$work = Join-Path ([IO.Path]::GetTempPath()) ('sxcommand-gfx-' + [Guid]::NewGuid().ToString('N'))

try {
    & java -jar $FFDec -export script (Join-Path $work 'base') $base | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'ffdec failed to export the base overlay' }

    $source = Join-Path $work "base\scripts\$class"
    $target = Join-Path $work "build\$class"
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null

    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $text = [IO.File]::ReadAllText($source, $utf8).TrimEnd()
    if (-not $text.EndsWith('}')) { throw 'unexpected class layout' }
    $text = $text.Substring(0, $text.Length - 1).TrimEnd()
    $merged = $text + "`n`n" + [IO.File]::ReadAllText($engine, $utf8) + "}`n"
    [IO.File]::WriteAllText($target, $merged, $utf8)

    & java -jar $FFDec -onerror abort -importScript $base $output (Join-Path $work 'build')
    if ($LASTEXITCODE -ne 0) { throw 'ffdec failed to compile the overlay' }

    Write-Host 'built core/SX_COMMAND.gfx'
}
finally {
    if (Test-Path $work) { Remove-Item -Recurse -Force $work }
}
