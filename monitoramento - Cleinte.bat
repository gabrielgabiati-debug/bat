@echo off

:: --- VERIFICA E FORÇA EXECUÇÃO COMO ADMINISTRADOR ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Solicitando privilegios de Administrador...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:: ----------------------------------------------------

set /p "SERIAL=Digite o SERIAL do cliente: "

echo,
echo [INFO] Serial informado: %SERIAL%

taskkill /f /im monitoramento.exe
net stop SGMonitoramento%SERIAL%

echo Removendo o servico antigo (SGMonitoramento%SERIAL%)...
sc delete SGMonitoramento%SERIAL%

timeout /t 3 /nobreak >nul

sc create SGMonitoramento%SERIAL% binpath= "C:\SGBR\Master\Monitoramento.exe" start= delayed-auto displayname= "Monitoramento de DF-e e integridade - SGBr Sistemas - %SERIAL%"


if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo [SUCESSO] Servico SGMonitoramento%SERIAL% criado com sucesso!
    echo ========================================================
    
    :: (Opcional) Já inicia o serviço automaticamente logo após criar
    echo Iniciando o serviço...
    net start SGMonitoramento%SERIAL% >nul 2>&1
) 

echo Processo concluido. O script sera excluido...
timeout /t 3 /nobreak >nul

:: COMANDO PARA SE AUTOEXCLUIR
(goto) 2>nul & del "%~f0"