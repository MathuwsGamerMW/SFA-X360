@echo off
rem ============================================================
rem CONFIGURACAO LOCAL - COPIE ESTE ARQUIVO COMO LOCAL_CONFIG.bat
rem LOCAL_CONFIG.bat deve permanecer FORA do Git.
rem ============================================================

rem XDK: normalmente detectado automaticamente pelo ambiente.
if not defined XEDK set "XEDK=C:\Program Files (x86)\Microsoft Xbox 360 SDK"

rem Exemplos de caminhos que podem variar entre computadores:
set "SFA_ORIGINAL="
set "SFA_EXTRACTED="
set "XENIA_PATH="
set "XBOX_IP="

rem Nunca coloque tokens/senhas neste arquivo se nao forem necessarios.
rem Se precisar de credenciais, prefira o gerenciador de credenciais do sistema.
