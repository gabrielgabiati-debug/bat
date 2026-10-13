@echo off
color 04
setlocal

:: --- VERIFICA E FORCA EXECUCAO COMO ADMINISTRADOR ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de Administrador...
    goto UACPrompt
)
goto gotAdmin

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //nologo "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%~dp0"

set "INSTALADOR=C:\SGBR\Master\Utilitarios\Firebird_Install_x64.exe"

:: ============================================================
:: [1/5] PARAR SERVICOS E PROCESSOS
:: ============================================================
echo [1/5] Parando servicos e encerrando processos do Firebird...
net stop FirebirdServerDefaultInstance
net stop FirebirdGuardianDefaultInstance
taskkill /f /im fbserver.exe
taskkill /f /im fbguard.exe
taskkill /f /im fb_inet_server.exe
taskkill /f /im instreg.exe
timeout /t 3 /nobreak >nul

:: ============================================================
:: [2/5] DESINSTALAR VERSAO ANTIGA
:: ============================================================
echo.
echo [2/5] Desinstalando versao antiga...
if exist "C:\Program Files (x86)\Firebird\Firebird_2_5\uninst.exe" (
    echo Encontrado desinstalador em Program Files ^(x86^)
    "C:\Program Files (x86)\Firebird\Firebird_2_5\uninst.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
    echo Codigo de retorno: %errorlevel%
    timeout /t 3 /nobreak >nul
) else (
    echo Desinstalador x86 nao encontrado.
)
if exist "C:\Program Files\Firebird\Firebird_2_5\uninst.exe" (
    echo Encontrado desinstalador em Program Files
    "C:\Program Files\Firebird\Firebird_2_5\uninst.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
    echo Codigo de retorno: %errorlevel%
    timeout /t 3 /nobreak >nul
) else (
    echo Desinstalador x64 nao encontrado.
)

:: ============================================================
:: [3/5] LIMPAR DIRETORIOS RESIDUAIS
:: ============================================================
echo.
echo [3/5] Limpando diretorios residuais...
if exist "C:\Program Files (x86)\Firebird\Firebird_2_5" (
    rd /s /q "C:\Program Files (x86)\Firebird\Firebird_2_5"
    echo Pasta x86 removida.
)
if exist "C:\Program Files\Firebird\Firebird_2_5" (
    rd /s /q "C:\Program Files\Firebird\Firebird_2_5"
    echo Pasta x64 removida.
)
timeout /t 3 /nobreak >nul

echo.
echo ===== VERIFICACAO DA REMOCAO =====
if exist "C:\Program Files (x86)\Firebird\Firebird_2_5" (echo [ATENCAO] Pasta x86 ainda existe) else (echo [OK] Pasta x86 nao existe mais)
if exist "C:\Program Files\Firebird\Firebird_2_5" (echo [ATENCAO] Pasta x64 ainda existe) else (echo [OK] Pasta x64 nao existe mais)
sc query FirebirdServerDefaultInstance >nul 2>&1
if %errorlevel% equ 0 (echo [ATENCAO] Servico Firebird ainda registrado) else (echo [OK] Servico Firebird nao esta mais registrado)

:: ============================================================
:: [4/5] REINSTALAR
:: ============================================================
echo.
echo [4/5] Reinstalando Firebird 2.5...
if not exist "%INSTALADOR%" (
    echo [ERRO] Instalador nao encontrado em:
    echo %INSTALADOR%
    echo.
    pause
    exit /b 1
)

start /wait "" "%INSTALADOR%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS="installServer,useSuperServer"
echo Codigo de retorno do instalador: %errorlevel%

if %errorlevel% neq 0 (
    echo [ERRO] Falha na instalacao.
    echo.
    pause
    exit /b %errorlevel%
)

:: ============================================================
:: [5/5] INICIAR SERVICOS
:: ============================================================
echo.
echo [5/5] Iniciando servicos do Firebird...
timeout /t 3 /nobreak >nul

sc query FirebirdServerDefaultInstance >nul 2>&1
if %errorlevel% neq 0 (
    echo [ATENCAO] Servico FirebirdServerDefaultInstance nao foi registrado pelo instalador.
) else (
    sc config FirebirdServerDefaultInstance start= auto >nul 2>&1
    sc config FirebirdGuardianDefaultInstance start= auto >nul 2>&1

    net start FirebirdGuardianDefaultInstance
    net start FirebirdServerDefaultInstance
)

echo.
echo ===== VERIFICACAO FINAL =====
if exist "C:\Program Files (x86)\Firebird\Firebird_2_5\bin\fbserver.exe" (echo [OK] Instalado em Program Files ^(x86^))
if exist "C:\Program Files\Firebird\Firebird_2_5\bin\fbserver.exe" (echo [OK] Instalado em Program Files)
echo.
echo Guardian:
sc query FirebirdGuardianDefaultInstance | findstr /i "STATE"
echo Server:
sc query FirebirdServerDefaultInstance | findstr /i "STATE"

echo.
echo [SUCESSO] Firebird 2.5 reinstalado!
echo.
pause

