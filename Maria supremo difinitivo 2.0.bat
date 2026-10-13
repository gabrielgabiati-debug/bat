@echo off
color 04
setlocal EnableExtensions EnableDelayedExpansion

:: =======================================================
:: CONFIGURACOES SGBR / MARIADB / HEIDISQL
:: =======================================================
set "HOST_DB=localhost"
set "PORTA_DB=3345"
set "USUARIO_DB=root"
set "SENHA_DB=masterkey"

:: Banco de origem e nome que sera usado na restauracao
set "NOME_BANCO=basesgmaster09102026164338"
set "NOVO_BANCO=basesgmaster_restaurado"

:: --- ELEVACAO DE PRIVILEGIOS ---
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:MENU
cls
echo ===================================================
echo       BACKUP SGBR SEM LOCKS NO DUMP
echo ===================================================
echo Servidor           : %HOST_DB%:%PORTA_DB%
echo Banco de origem    : %NOME_BANCO%
echo Nome para restaurar: %NOVO_BANCO%
echo ===================================================
echo.
echo [1] Gerar backup SQL sem LOCK TABLES
echo [2] Verificar tabelas (reparo automatico)
echo [3] Backup e depois verificar/reparar
echo [4] Sair
echo.
set "OPCAO="
set /p "OPCAO=Escolha (1-4): "

if "%OPCAO%"=="1" goto OPCAO_BACKUP
if "%OPCAO%"=="2" goto OPCAO_REPARAR
if "%OPCAO%"=="3" goto OPCAO_AMBOS
if "%OPCAO%"=="4" exit /b

echo Opcao invalida.
pause
goto MENU

:OPCAO_BACKUP
call :FUNC_BACKUP
echo.
pause
goto MENU

:OPCAO_REPARAR
call :FUNC_REPARAR
echo.
pause
goto MENU

:OPCAO_AMBOS
call :FUNC_BACKUP
if errorlevel 1 (
    echo [AVISO] Backup falhou; reparo nao sera iniciado.
    pause
    goto MENU
)
call :FUNC_REPARAR
echo.
pause
goto MENU

:: =======================================================
:: FUNCAO DE BACKUP
:: =======================================================
:FUNC_BACKUP
echo.
echo ===================================================
echo GERANDO DUMP SEM LOCK TABLES
echo ===================================================

set "MYSQLDUMP_BIN="
for /f "delims=" %%i in ('where mysqldump 2^>nul') do set "MYSQLDUMP_BIN=%%i"

if not defined MYSQLDUMP_BIN (
    for /d %%D in ("C:\SGBR\MariaDB*" "C:\SGBR\MySQL*" "C:\Program Files\MariaDB*" "C:\Program Files (x86)\MariaDB*" "C:\Program Files\MySQL*") do (
        if exist "%%~D\bin\mysqldump.exe" set "MYSQLDUMP_BIN=%%~D\bin\mysqldump.exe"
        if exist "%%~D\mysqldump.exe" set "MYSQLDUMP_BIN=%%~D\mysqldump.exe"
    )
)

if not defined MYSQLDUMP_BIN (
    echo [ERRO] mysqldump.exe nao foi encontrado.
    exit /b 1
)

set "DESTINO_BACKUP="
for /f "delims=" %%I in ('powershell -NoProfile -Command "$d=(New-Object -ComObject Shell.Application).BrowseForFolder(0, 'Selecione a pasta para salvar o backup SQL', 0, 0); if ($d) { $d.Self.Path }"') do set "DESTINO_BACKUP=%%I"

if not defined DESTINO_BACKUP (
    echo [AVISO] Nenhuma pasta selecionada. Usando C:\Backup_SGBR
    set "DESTINO_BACKUP=C:\Backup_SGBR"
)
if not exist "!DESTINO_BACKUP!" mkdir "!DESTINO_BACKUP!" 2>nul
if not exist "!DESTINO_BACKUP!" (
    echo [ERRO] Nao foi possivel criar/acessar a pasta de backup.
    exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "DATA_HORA=%%i"
set "ARQUIVO_BACKUP=!DESTINO_BACKUP!\backup_%NOME_BANCO%_!DATA_HORA!.sql"
set "ERRO_LOG=!DESTINO_BACKUP!\err_log.txt"
set "TEMP_SQL=!DESTINO_BACKUP!\dump_temp_!DATA_HORA!.sql"

echo Banco de origem: %NOME_BANCO%
echo Banco para restauracao: %NOVO_BANCO%
echo Arquivo: "!ARQUIVO_BACKUP!"
echo.
echo Exportando sem LOCK TABLES e sem ADD LOCKS...

:: Nao usar --databases: assim o dump nao fixa o nome do banco original.
:: As opcoes skip evitam instrucoes explicitas de LOCK/UNLOCK TABLES no dump.
"!MYSQLDUMP_BIN!" -h "%HOST_DB%" -P "%PORTA_DB%" -u "%USUARIO_DB%" -p"%SENHA_DB%" --default-character-set=utf8mb4 --single-transaction --quick --skip-add-locks --skip-lock-tables --routines --events --triggers "%NOME_BANCO%" > "!TEMP_SQL!" 2> "!ERRO_LOG!"

if errorlevel 1 (
    echo [ERRO] O mysqldump falhou:
    if exist "!ERRO_LOG!" type "!ERRO_LOG!"
    del "!TEMP_SQL!" >nul 2>&1
    exit /b 1
)

if not exist "!TEMP_SQL!" (
    echo [ERRO] O arquivo temporario nao foi criado.
    exit /b 1
)

for %%F in ("!TEMP_SQL!") do set "TAMANHO=%%~zF"
if not defined TAMANHO set "TAMANHO=0"
if !TAMANHO! LEQ 0 (
    echo [ERRO] O dump esta vazio.
    if exist "!ERRO_LOG!" type "!ERRO_LOG!"
    del "!TEMP_SQL!" >nul 2>&1
    exit /b 1
)

:: Acrescenta USE com o novo nome, para importar no banco de destino.
:: O banco de destino precisa existir antes da importacao no HeidiSQL.
(
    echo -- Backup sem instrucoes LOCK TABLES / UNLOCK TABLES
    echo -- Origem: %NOME_BANCO%
    echo -- Destino esperado: %NOVO_BANCO%
    echo CREATE DATABASE IF NOT EXISTS `%NOVO_BANCO%`;
    echo USE `%NOVO_BANCO%`;
    type "!TEMP_SQL!"
) > "!ARQUIVO_BACKUP!"

del "!TEMP_SQL!" >nul 2>&1

if not exist "!ARQUIVO_BACKUP!" (
    echo [ERRO] O arquivo SQL final nao foi criado.
    exit /b 1
)

findstr /i /c:"LOCK TABLES" /c:"UNLOCK TABLES" "!ARQUIVO_BACKUP!" >nul
if not errorlevel 1 (
    echo [AVISO] Foram encontradas linhas com LOCK/UNLOCK no arquivo. Verifique antes de importar.
) else (
    echo [OK] Nenhuma instrucao LOCK TABLES ou UNLOCK TABLES encontrada.
)

for %%F in ("!ARQUIVO_BACKUP!") do set "TAMANHO_FINAL=%%~zF"
echo.
echo [SUCESSO] Dump gerado.
echo Arquivo: "!ARQUIVO_BACKUP!"
echo Tamanho: !TAMANHO_FINAL! bytes.
echo.
echo IMPORTANTE: antes de importar, confirme que o banco %NOVO_BANCO% existe.
echo O arquivo foi preparado para usar esse banco como destino.
if exist "!ERRO_LOG!" del "!ERRO_LOG!" >nul 2>&1
exit /b 0

:: =======================================================
:: FUNCAO DE VERIFICACAO / REPARO
:: =======================================================
:FUNC_REPARAR
echo.
echo ===================================================
echo VERIFICACAO / REPARO: %NOME_BANCO%
echo ===================================================

set "MYSQLCHECK_BIN="
for /f "delims=" %%i in ('where mysqlcheck 2^>nul') do set "MYSQLCHECK_BIN=%%i"

if not defined MYSQLCHECK_BIN (
    for /d %%D in ("C:\SGBR\MariaDB*" "C:\SGBR\MySQL*" "C:\Program Files\MariaDB*" "C:\Program Files (x86)\MariaDB*" "C:\Program Files\MySQL*") do (
        if exist "%%~D\bin\mysqlcheck.exe" set "MYSQLCHECK_BIN=%%~D\bin\mysqlcheck.exe"
    )
)

if not defined MYSQLCHECK_BIN (
    echo [ERRO] mysqlcheck.exe nao foi encontrado.
    exit /b 1
)

echo Executando verificacao e reparo automatico...
"!MYSQLCHECK_BIN!" -h "%HOST_DB%" -P "%PORTA_DB%" -u "%USUARIO_DB%" -p"%SENHA_DB%" --auto-repair --check "%NOME_BANCO%"
if errorlevel 1 (
    echo [AVISO] O comando retornou erro. Consulte as mensagens acima.
    exit /b 1
)
echo [OK] Verificacao concluida.
exit /b 0
