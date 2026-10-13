@echo off
color 04
rem --- Elevação de privilégios para Administrador ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

rem --- Encerra processos rodando na pasta C:\SGBR ---
echo Procurando e encerrando processos em C:\SGBR...
powershell -NoProfile -Command "$achou = $false; Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -like 'C:\SGBR\*' } | ForEach-Object { $achou = $true; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue; Write-Host ('Finalizado: ' + $_.Name + ' (PID ' + $_.ProcessId + ')') }; if (-not $achou) { Write-Host 'Nenhum processo em execucao encontrado.' }"
echo.

setlocal enabledelayedexpansion

set "RAIZ=C:\SGBR\Master"

echo Acessando o diretorio %RAIZ%...
if not exist "%RAIZ%" (
    echo A pasta raiz "%RAIZ%" nao foi encontrada!
    pause
    exit /b
)

cd /d "%RAIZ%"

echo.
echo ===================================================
echo 1. Apagando arquivos e DLLs...
echo ===================================================
rem Apaga arquivos com extensao .pendingoverwrite e com DotNetZip no nome
del /f /s /q "*.pendingoverwrite" 2>nul
del /f /s /q "*DotNetZip*" 2>nul

rem Apaga DLLs do FastReport
del /f /q "FastReport.Bars.dll" 2>nul
del /f /q "FastReport.Compat.dll" 2>nul
del /f /q "FastReport.DataVisualization.dll" 2>nul
del /f /q "FastReport.dll" 2>nul
del /f /q "FastReport.Editor.dll" 2>nul
del /f /q "FastReport.Firebird.dll" 2>nul
del /f /q "FastReport.MySQL.dll" 2>nul
echo Arquivos removidos com sucesso.

echo.
echo ===================================================
echo 2. Apagando pastas 'Schemas' e 'ACBrLib'...
echo ===================================================
for /d %%D in (*Schemas*) do (
    echo Removendo pasta: %%D
    rmdir /s /q "%%D" 2>nul
)

if exist "ACBrLib" (
    echo Removendo pasta: ACBrLib
    rmdir /s /q "ACBrLib" 2>nul
)

echo.
echo ===================================================
echo 3. Exclusao do Executavel
echo ===================================================
set "NOME_EXE="
set /p "NOME_EXE=Digite o nome do executavel (ex: Menu.exe) ou pressione ENTER para pular: "

if defined NOME_EXE (
    if exist "!NOME_EXE!" (
        del /f /q "!NOME_EXE!"
        echo Executavel "!NOME_EXE!" excluido com sucesso.
    ) else (
        echo O arquivo "!NOME_EXE!" nao foi encontrado.
    )
) else (
    echo Nenhum executavel informado. Pulando etapa...
)

echo.
echo ===================================================
echo 4. Iniciando Atualizar.exe e Menu.exe...
echo ===================================================
if exist "Atualizar.exe" (
    echo Aguardando a atualizacao terminar...
    start /wait "" "Atualizar.exe"
    echo Processo de atualizacao concluido.

    if exist "Menu.exe" (
        start "" "Menu.exe"
        echo Menu.exe iniciado.
    ) else (
        echo [ERRO] Menu.exe nao foi encontrado apos a atualizacao.
    )
) else (
    echo [ERRO] O arquivo Atualizar.exe nao foi encontrado na raiz.
)

echo.
pause


:: COMANDO PARA SE AUTOEXCLUIR
(goto) 2>nul & del "%~f0"