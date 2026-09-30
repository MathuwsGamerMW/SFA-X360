@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Salvar projeto no GitHub
cd /d "%~dp0"
if exist "C:\Program Files\Git\cmd\git.exe" set "PATH=C:\Program Files\Git\cmd;%PATH%"

call :CHECK
if errorlevel 1 exit /b 1

echo ============================================================
echo  SALVAR PROJETO - este computador para GitHub
echo ============================================================
echo.
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%B"
echo Repositorio: %cd%
echo Branch: !BRANCH!
echo.

for /f "delims=" %%N in ('git config user.name 2^>nul') do set "GITNAME=%%N"
for /f "delims=" %%E in ('git config user.email 2^>nul') do set "GITEMAIL=%%E"
if not defined GITNAME (
  set /p "GITNAME=Primeiro uso - seu nome para os commits: "
  if not defined GITNAME goto FAIL
  git config user.name "!GITNAME!"
)
if not defined GITEMAIL (
  set /p "GITEMAIL=Primeiro uso - seu e-mail do Git/GitHub: "
  if not defined GITEMAIL goto FAIL
  git config user.email "!GITEMAIL!"
)

git status --short
echo.
set "CHANGED="
for /f "delims=" %%S in ('git status --porcelain') do set "CHANGED=1"
if not defined CHANGED (
  echo Nao existem arquivos alterados para salvar.
  echo Vou apenas conferir se ha commits locais pendentes.
  goto PUSH_ONLY
)

set /p "MSG=Descreva resumidamente o que foi feito: "
if not defined MSG (
  for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "STAMP=%%T"
  set "MSG=Sincronizacao !STAMP!"
)
set "MSG=!MSG:"='!"

echo.
echo Adicionando alteracoes...
git add -A
if errorlevel 1 goto FAIL

git diff --cached --quiet
if not errorlevel 1 (
  echo Nenhuma alteracao valida para commit.
  goto PUSH_ONLY
)

if exist "%~dp0security\CHECK_BEFORE_PUSH.ps1" (
  echo.
  echo Verificando seguranca antes do commit...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0security\CHECK_BEFORE_PUSH.ps1"
  if errorlevel 1 (
    echo.
    echo PUSH CANCELADO por seguranca.
    pause
    exit /b 10
  )
)

git commit -m "!MSG!"
if errorlevel 1 goto FAIL

:PUSH_ONLY
echo.
echo Atualizando referencias remotas...
git fetch origin
if errorlevel 1 goto FAIL

git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >nul 2>&1
if errorlevel 1 (
  echo Primeira publicacao desta branch: !BRANCH!
  git push -u origin "!BRANCH!"
  if errorlevel 1 goto FAIL
  goto OK
)

echo Integrando eventuais mudancas remotas com rebase...
git pull --rebase
if errorlevel 1 (
  echo.
  echo ATENCAO: houve conflito ou falha no rebase.
  echo O push NAO foi feito. Resolva o conflito antes.
  pause
  exit /b 4
)

echo Enviando ao GitHub...
git push
if errorlevel 1 goto FAIL

:OK
echo.
echo Projeto salvo no GitHub com sucesso.
git status -sb
pause
exit /b 0

:CHECK
where git >nul 2>&1 || (echo ERRO: Git nao instalado/no PATH. & pause & exit /b 1)
git rev-parse --is-inside-work-tree >nul 2>&1 || (echo ERRO: coloque este BAT na raiz de um repositorio Git. & pause & exit /b 1)
git remote get-url origin >nul 2>&1 || (echo ERRO: remoto "origin" nao configurado. & pause & exit /b 1)
exit /b 0

:FAIL
echo.
echo ERRO: operacao interrompida. Nada sera forcado.
git status -sb
pause
exit /b 1
