@echo off
setlocal enabledelayedexpansion

rem ===== FIREBIRD 2.5 =====
set "FB_BIN=C:\Program Files\Firebird\Firebird_2_5\bin"
set "DB_PATH=localhost:C:\SGBR\MASTER\BD\BASESGMASTER_BET.FDB"
set "DB_USER=SYSDBA"
set "DB_PASS=masterkey"

rem ===== SESSAO DO SITE (cookie acesso_restrito_session) =====
set "SESSAO=eyJpdiI6IkdqXC8wRDNvMkNXWng3WkNSd25lcVV3PT0iLCJ2YWx1ZSI6InJnYWNGVFBDdjlcLyt2MlVOSlZjT3Y5NndMNWpcL0RXWk1EWmdtbTdtMGpjSzN3K0ZiYytRWlhyZ3pCVGlnQURYUyIsIm1hYyI6ImZmNjdkMDc5Mzk3OWMwZjk5MmI4ODBhMzY1NTcyZmJjN2I3N2IzOGIzZWM0ZmQ3MjE0NTIyNGE4YmI3NjQyNGMifQ%%3D%%3D"

set "SQL=%TEMP%\consulta_serial.sql"
set "LISTA=%TEMP%\consulta_serial.txt"

> "%SQL%" echo SET HEADING OFF;
>> "%SQL%" echo SELECT DISTINCT cnpj FROM temitente WHERE cnpj IS NOT NULL;

"%FB_BIN%\isql.exe" -user %DB_USER% -password %DB_PASS% -ch WIN1252 -i "%SQL%" -o "%LISTA%" "%DB_PATH%"
if errorlevel 1 (
    echo Erro ao consultar o banco Firebird.
    pause
    exit /b 1
)

for /f "usebackq tokens=* delims= " %%C in ("%LISTA%") do (
    set "CNPJ=%%C"
    set "CNPJ=!CNPJ:.=!"
    set "CNPJ=!CNPJ:/=!"
    set "CNPJ=!CNPJ:-=!"
    set "CNPJ=!CNPJ: =!"

    if not "!CNPJ!"=="" (
        echo ------------------------------------------
        echo CNPJ: !CNPJ!

        rem Montando a URL da API com o CNPJ atual (%% nas porcentagens para o CMD nao confundir com variavel)
        set "URL=https://acessorestrito.sgbr.com.br/seriais/get?arrayfiltro%%5B%%5D=1&arrayfiltro%%5B%%5D=2&arrayfiltro%%5B%%5D=3&arrayfiltro%%5B%%5D=4&arrayfiltro%%5B%%5D=5&arrayfiltro%%5B%%5D=6&filtro%%5Bdatai%%5D=0&filtro%%5Bdataf%%5D=0&filtro%%5Bcodvendedor%%5D=-1&filtro%%5Bnomevendedor%%5D=&filtro%%5Bbusca%%5D=!CNPJ!&filtro%%5BftDtLiberada%%5D=true&filtro%%5BprimeiroCarregamento%%5D=1&filtro%%5Bsgbr%%5D=true&filtro%%5Bjcs%%5D=true"

        rem Executando a requisicao via cURL
        curl -s -X GET "!URL!" ^
             -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36" ^
             -H "X-Requested-With: XMLHttpRequest" ^
             -b "acesso_restrito_session=%SESSAO%"

        echo.
        timeout /t 2 >nul
    )
)

del "%SQL%" 2>nul
del "%LISTA%" 2>nul
echo.
echo Concluido!
pause
