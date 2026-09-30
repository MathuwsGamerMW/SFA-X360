$ErrorActionPreference = 'Stop'

$git = (Get-Command git -ErrorAction Stop).Source
$root = (& $git rev-parse --show-toplevel).Trim()
if (-not $root) { throw 'Repositorio Git nao encontrado.' }

Set-Location $root
$files = @(& $git diff --cached --name-only --diff-filter=ACMR)
if ($files.Count -eq 0) {
    Write-Host '[SECURITY] Nenhum arquivo staged para verificar.'
    exit 0
}

$blockedExtensions = @(
    '.iso','.gcm','.rvz','.wia','.wbfs','.wad',
    '.xex','.xbe','.pfx','.p12','.pem','.key',
    '.keystore','.pdb','.ilk','.idb','.sdf','.suo'
)

$blockedPathRegex = @(
    '(^|/)(orig|rom|roms|dump|dumps|extracted|game_files|original_files)(/|$)',
    '(^|/)(xdk|sdk|xbox360sdk|xbox_360_sdk)(/|$)',
    '(^|/)(debug|release|build|out|bin|obj)(/|$)',
    '(^|/)(local_config\.(bat|ps1)|\.env($|\.)|secrets\.|credentials\.)'
)
$violations = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $normalized = $file.Replace('\','/')
    $ext = [IO.Path]::GetExtension($normalized).ToLowerInvariant()

    if ($blockedExtensions -contains $ext) {
        $violations.Add("Extensao bloqueada: $file")
        continue
    }

    foreach ($rx in $blockedPathRegex) {
        if ($normalized -match $rx) {
            $violations.Add("Caminho bloqueado: $file")
            break
        }
    }
}

# Varredura de conteudo staged para segredos/caminhos da maquina.
$secretPatterns = @(
    'github_pat_[A-Za-z0-9_]{20,}',
    'gh[pousr]_[A-Za-z0-9]{20,}',
    '-----BEGIN [A-Z ]*PRIVATE KEY-----',
    '(?i)authorization\s*:\s*bearer\s+[A-Za-z0-9._\-]{12,}'
)

$userProfile = [Regex]::Escape($env:USERPROFILE)
foreach ($file in $files) {
    if ($violations | Where-Object { $_ -like "*$file*" }) { continue }

    $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
    $textExt = @(
        '.c','.cc','.cpp','.cxx','.h','.hpp','.inl',
        '.txt','.md','.bat','.cmd','.ps1','.py',
        '.json','.xml','.yml','.yaml','.ini','.cfg',
        '.sln','.vcproj','.vcxproj','.props','.targets'
    )
    if ($textExt -notcontains $ext) { continue }

    $content = (& $git show ":$file" 2>$null | Out-String)
    if (-not $content) { continue }

    if ($env:USERPROFILE -and $content -match $userProfile) {
        $violations.Add("Caminho pessoal da maquina encontrado em: $file")
    }

    foreach ($rx in $secretPatterns) {
        if ($content -match $rx) {
            $violations.Add("Possivel segredo/token encontrado em: $file")
            break
        }
    }
}
if ($violations.Count -gt 0) {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ' PUSH BLOQUEADO - REVISAO DE SEGURANCA FALHOU' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    foreach ($v in $violations | Sort-Object -Unique) {
        Write-Host (" - " + $v) -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host 'Remova esses arquivos/dados do staging e tente novamente.'
    Write-Host 'Nada foi enviado ao remoto.'
    exit 10
}

Write-Host '[SECURITY] Verificacao concluida: nenhum item sensivel conhecido no staging.' -ForegroundColor Green
exit 0
