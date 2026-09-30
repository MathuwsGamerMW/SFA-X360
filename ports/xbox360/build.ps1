param(
    [string]$Xedk = $env:XEDK,
    [string]$XexTool = $env:XEXTOOL,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Join-Path $Root "build"
$DistDir = Join-Path $Root "dist"
$Source = Join-Path $Root "src\main.cpp"
$XexConfig = Join-Path $Root "xex.xml"

if ($Clean) {
    Remove-Item $BuildDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $DistDir -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Force -Path $BuildDir, $DistDir | Out-Null

if ([string]::IsNullOrWhiteSpace($Xedk)) {
    throw "Xbox 360 XDK ausente. Defina XEDK ou passe -Xedk com a raiz do XDK 2.0.21256.3."
}

if (-not (Test-Path $Xedk)) {
    throw "Diretorio XDK nao encontrado: $Xedk"
}
$ToolDir = Join-Path $Xedk "bin\win32"
$IncludeDir = Join-Path $Xedk "include\xbox"
$LibDir = Join-Path $Xedk "lib\xbox"
$Compiler = Join-Path $ToolDir "cl.exe"
$Linker = Join-Path $ToolDir "link.exe"
$ImageXex = Join-Path $ToolDir "imagexex.exe"

$Required = @(
    $Compiler,
    $Linker,
    $ImageXex,
    (Join-Path $IncludeDir "xtl.h"),
    (Join-Path $LibDir "xboxkrnl.lib"),
    (Join-Path $LibDir "xapilib.lib"),
    (Join-Path $LibDir "d3d9.lib")
)

$Missing = @($Required | Where-Object { -not (Test-Path $_) })
if ($Missing.Count -gt 0) {
    $MissingText = $Missing -join [Environment]::NewLine
    throw "XDK incompleto. Arquivos ausentes:$([Environment]::NewLine)$MissingText"
}

if ([string]::IsNullOrWhiteSpace($XexTool)) {
    $FoundXexTool = Get-Command xextool.exe -ErrorAction SilentlyContinue
    if ($FoundXexTool) {
        $XexTool = $FoundXexTool.Source
    }
}
if ([string]::IsNullOrWhiteSpace($XexTool) -or -not (Test-Path $XexTool)) {
    throw "XexTool nao encontrado. Defina XEXTOOL ou passe -XexTool com o caminho de xextool.exe."
}

$Object = Join-Path $BuildDir "main.obj"
$Executable = Join-Path $BuildDir "SFA-X360.exe"
$DevkitXex = Join-Path $BuildDir "SFA-X360-devkit.xex"
$RetailXex = Join-Path $DistDir "default.xex"

$PreviousInclude = $env:INCLUDE
$PreviousLib = $env:LIB
$env:INCLUDE = $IncludeDir
$env:LIB = $LibDir

try {
    & $Compiler /c /nologo /W3 /O2 /D_XBOX /D_XBOX360 /MT /GS- /GR- /GF /Gy /fp:fast /Zc:wchar_t /Zc:forScope "/Fo$Object" $Source
    if ($LASTEXITCODE -ne 0) {
        throw "Falha do compilador XDK: codigo $LASTEXITCODE"
    }

    & $Linker /nologo /incremental:no /opt:ref /opt:icf /xex:no "/out:$Executable" $Object xapilib.lib d3d9.lib xboxkrnl.lib libcmt.lib
    if ($LASTEXITCODE -ne 0) {
        throw "Falha do linker XDK: codigo $LASTEXITCODE"
    }

    & $ImageXex -nologo "-config:$XexConfig" "-out:$DevkitXex" $Executable
    if ($LASTEXITCODE -ne 0) {
        throw "Falha do ImageXex: codigo $LASTEXITCODE"
    }

    Copy-Item $DevkitXex $RetailXex -Force
    & $XexTool -c c -e e -r a -m r $RetailXex
    if ($LASTEXITCODE -ne 0) {
        throw "Falha do XexTool: codigo $LASTEXITCODE"
    }

    $XexInfo = (& $XexTool -l $RetailXex | Out-String)
    if ($XexInfo -notmatch "(?m)^\s*Retail\s*$") {
        throw "default.xex gerado, mas o XexTool nao o identificou como Retail."
    }

    Write-Output "Build Xbox 360 concluido."
    Write-Output "Devkit: $DevkitXex"
    Write-Output "RGH:    $RetailXex"
}
finally {
    $env:INCLUDE = $PreviousInclude
    $env:LIB = $PreviousLib
}