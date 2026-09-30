@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Status do projeto Git
cd /d "%~dp0"
if exist "C:\Program Files\Git\cmd\git.exe" set "PATH=C:\Program Files\Git\cmd;%PATH%"

where git >nul 2>&1 || (echo ERRO: Git nao instalado/no PATH. & pause & exit /b 1)
git rev-parse --is-inside-work-tree >nul 2>&1 || (echo ERRO: coloque este BAT na raiz de um repositorio Git. & pause & exit /b 1)

echo ============================================================
echo  STATUS DO PROJETO
echo ============================================================
echo.
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%B"
echo Pasta: %cd%
echo Branch: !BRANCH!

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "REMOTE=%%R"
if defined REMOTE (echo GitHub/origin: !REMOTE!) else (echo GitHub/origin: NAO CONFIGURADO)

echo.
echo Buscando estado remoto...
git fetch --all --prune >nul 2>&1
echo.
git status -sb
echo.
echo Ultimo commit local:
git log -1 --date=local --pretty=format:"%%h - %%ad - %%s"
echo.
echo.

set "CHANGED="
for /f "delims=" %%S in ('git status --porcelain') do set "CHANGED=1"
if defined CHANGED (
  echo [ATENCAO] Existem arquivos modificados/novos nao commitados.
) else (
  echo [OK] Nao ha alteracoes locais pendentes.
)

git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >nul 2>&1
if errorlevel 1 (
  echo [ATENCAO] A branch nao possui upstream configurado.
) else (
  for /f "tokens=1,2" %%A in ('git rev-list --left-right --count "HEAD...@{u}"') do (
    echo Commits locais ainda nao enviados: %%A
    echo Commits remotos ainda nao baixados: %%B
  )
)

echo.
pause
