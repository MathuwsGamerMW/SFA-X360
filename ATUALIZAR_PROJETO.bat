@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Atualizar projeto do GitHub
cd /d "%~dp0"
if exist "C:\Program Files\Git\cmd\git.exe" set "PATH=C:\Program Files\Git\cmd;%PATH%"

call :CHECK
if errorlevel 1 exit /b 1

echo ============================================================
echo  ATUALIZAR PROJETO - GitHub para este computador
echo ============================================================
echo.
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%B"
echo Repositorio: %cd%
echo Branch: !BRANCH!
echo.

for /f "delims=" %%S in ('git status --porcelain') do set "DIRTY=1"
if defined DIRTY (
  echo ERRO: existem alteracoes locais ainda nao salvas.
  echo Use SALVAR_NO_GITHUB.bat antes de atualizar.
  echo.
  git status --short
  pause
  exit /b 2
)
echo Buscando atualizacoes...
git fetch --all --prune
if errorlevel 1 goto FAIL

git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >nul 2>&1
if errorlevel 1 (
  echo.
  echo ERRO: esta branch ainda nao possui upstream remoto.
  echo Configure o repositorio/origin antes de usar este BAT.
  pause
  exit /b 3
)

echo Aplicando somente atualizacao segura fast-forward...
git pull --ff-only
if errorlevel 1 goto FAIL

echo.
echo Projeto atualizado com sucesso.
git status -sb
echo.
pause
exit /b 0

:CHECK
where git >nul 2>&1 || (echo ERRO: Git nao instalado/no PATH. & pause & exit /b 1)
git rev-parse --is-inside-work-tree >nul 2>&1 || (echo ERRO: coloque este BAT na raiz de um repositorio Git. & pause & exit /b 1)
exit /b 0

:FAIL
echo.
echo Nao foi possivel atualizar automaticamente.
echo Nenhum merge forcado foi realizado.
pause
exit /b 1
