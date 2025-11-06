@echo off
setlocal
title Subida de PadronCompletoDB.sqlite3 a GitHub


echo ============================================
echo   SUBIENDO PadronCompletoDB.sqlite3 A GITHUB
echo ============================================

REM === Obtener la ruta del .bat actual (soporta espacios y acentos)
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%PublishPadron.ps1"

REM === Verificar existencia del .ps1
if not exist "%PS_SCRIPT%" (
    echo No se encontró el script PowerShell:
    echo %PS_SCRIPT%
    pause
    exit /b 1
)

echo Ejecutando PowerShell...
echo (No cierres esta ventana, el proceso puede tardar)
echo.

REM === Ejecutar PowerShell dentro de la misma consola y mantenerla abierta al finalizar
powershell.exe -NoExit -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%"

echo.
echo ============================================
echo   PROCESO FINALIZADO
echo ============================================
pause


