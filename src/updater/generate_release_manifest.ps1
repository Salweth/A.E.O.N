param(
  [string]$Repo = "Salweth/A.E.O.N",
  [string]$Branch = "main",
  [string]$Version = "2.0.0-alpha"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$rootfsPath = Join-Path $projectRoot "rootfs"
$manifestPath = Join-Path $scriptDir "release_manifest.lua"

function To-LuaString([string]$Value) {
  return '"' + ($Value -replace '\\', '\\' -replace '"', '\"') + '"'
}

if (-not (Test-Path $rootfsPath)) {
  throw "Missing rootfs directory: $rootfsPath"
}

$fileEntries = Get-ChildItem -Path $rootfsPath -Recurse -File |
  Sort-Object FullName |
  ForEach-Object {
    $relative = $_.FullName.Substring($rootfsPath.Length + 1).Replace('\', '/')
    [pscustomobject]@{
      Source = "src/rootfs/$relative"
      Target = "/" + $relative
    }
  }

$directories = @(
  "/bin",
  "/aeon",
  "/aeon/apps",
  "/aeon/config",
  "/aeon/data",
  "/aeon/install",
  "/aeon/lib",
  "/aeon/lib/aeon",
  "/aeon/runtime"
)
$directories += $fileEntries |
  ForEach-Object {
    Split-Path $_.Target -Parent
  } |
  Where-Object { $_ -and $_ -ne "\" } |
  ForEach-Object { $_.Replace('\', '/') }

$directories = $directories |
  Sort-Object -Unique

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("return {")
$lines.Add("  version = $(To-LuaString $Version),")
$lines.Add("  repo = $(To-LuaString $Repo),")
$lines.Add("  branch = $(To-LuaString $Branch),")
$lines.Add("  directories = {")

foreach ($directory in $directories) {
  $lines.Add("    $(To-LuaString $directory),")
}

$lines.Add("  },")
$lines.Add("  files = {")

foreach ($file in $fileEntries) {
  $lines.Add("    {")
  $lines.Add("      source = $(To-LuaString $file.Source),")
  $lines.Add("      target = $(To-LuaString $file.Target)")
  $lines.Add("    },")
}

$lines.Add("  }")
$lines.Add("}")

$content = [string]::Join("`n", $lines) + "`n"
[System.IO.File]::WriteAllText($manifestPath, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "Release manifest generated:" $manifestPath
