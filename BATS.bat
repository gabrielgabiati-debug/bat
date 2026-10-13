@echo off
title Gerenciador de Scripts - GitHub
color 0A

:: =======================================================
:: VERIFICACAO DE SENHA
:: =======================================================
set "SENHA_CORRETA=sua_senha_aqui"

echo ===============================================
echo         AUTENTICACAO NECESSARIA
echo ===============================================
set /p "senha_digitada=Digite a senha para acessar o menu: "

if not "%senha_digitada%"=="%SENHA_CORRETA%" (
    echo.
    echo [ERRO] Senha incorreta! Abrindo instrucoes...
    
    :: Tenta abrir o README.md local ou baixado
    if exist "README.md" (
        start "" "README.md"
    ) else (
        echo [AVISO] Arquivo README.md nao encontrado na pasta.
    )
    
    timeout /t 3 >nul
    exit /b
)



:: Eleva automaticamente para Administrador se necessário
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Solicitando permissao de Administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:menu
cls
echo ===============================================
echo            MENU DE EXECUCAO - GITHUB           
echo ===============================================
echo.
echo  [1] Executar Script Basico - Cliente
echo  [2] Executar Script de Monitoramento - Cliente
echo  [3] Executar Script Reinstalar Firebird
echo  [4] Executar Script Maria Supremo Definitivo 2.0
echo  [5] Sair
echo.
echo ===============================================

set /p opcao="Escolha uma opcao [1-5]: "

if "%opcao%"=="1" goto BASICO
if "%opcao%"=="2" goto MONITORAMENTO
if "%opcao%"=="3" goto FIREBIRD
if "%opcao%"=="4" goto MARIA
if "%opcao%"=="5" goto SAIR

echo.
echo Opcao invalida! Tente novamente...
timeout /t 2 >nul
goto menu

:BASICO
echo.
echo [1/2] Baixando script 'Basico - Cliente'...
curl -s -o temp_basico.bat "https://raw.githubusercontent.com/gabrielgabiati-debug/bat/refs/heads/main/basico%%20-%%20Cliente.bat"

echo [2/2] Executando script...
call temp_basico.bat

if exist temp_basico.bat del temp_basico.bat
goto FINALIZAR

:MONITORAMENTO
echo.
echo [1/2] Baixando script 'Monitoramento - Cliente'...
curl -s -o temp_monitoramento.bat "https://raw.githubusercontent.com/gabrielgabiati-debug/bat/refs/heads/main/monitoramento%%20-%%20Cleinte.bat"

echo [2/2] Executando script...
call temp_monitoramento.bat

if exist temp_monitoramento.bat del temp_monitoramento.bat
goto FINALIZAR

:FIREBIRD
echo.
echo [1/2] Baixando script 'Reinstalar Firebird'...
curl -s -o temp_firebird.bat "https://raw.githubusercontent.com/gabrielgabiati-debug/bat/refs/heads/main/reinstalar%%20firebird.bat"

echo [2/2] Executando script...
call temp_firebird.bat

if exist temp_firebird.bat del temp_firebird.bat
goto FINALIZAR

:MARIA
echo.
echo [1/2] Baixando script 'Maria Supremo Definitivo 2.0'...
curl -s -o temp_maria.bat "https://raw.githubusercontent.com/gabrielgabiati-debug/bat/refs/heads/main/Maria%%20supremo%%20difinitivo%%202.0.bat"

echo [2/2] Executando script...
call temp_maria.bat

if exist temp_maria.bat del temp_maria.bat
goto FINALIZAR

:FINALIZAR
echo.
echo Execucao finalizada! Fechando...
timeout /t 2 >nul
exit

:SAIR
echo Saindo...
exit
