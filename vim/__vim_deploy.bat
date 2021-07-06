@REM v0.1.0
@REM 2021-07-06
@REM https://lxvs.net/cloudconf

@echo off
@setlocal EnableExtensions EnableDelayedExpansion

@set "batchname=%~nx0"
@set "batchfolder=%~dp0"
@if "%batchfolder:~-1%" == "\" set "batchfolder=%batchfolder:~0,-1%"

set "dirTxt=cloudconf-vim-dir.txt"
set "verTxt=cloudconf-vim-ver.txt"

@set "cRed=[91m"
@set "cGrn=[92m"
@set "cYlw=[93m"
@set "cSuf=[0m"

@echo;
@echo     %cYlw%Vim%cSuf%
@echo;

pushd %~dp0

@if not defined vimDir (
    if exist "%dirTxt%" (
        for /f "usebackq delims=" %%i in ("%dirTxt%") do if not defined vimDir (
            set "folderPath=%%~i"
            call set "folderPath=!folderPath!"
            for %%j in ("!folderPath!\") do (
                if exist "%%~fj" (
                    set "vimDir=%%~fj"
                ) else (
                    >&2 echo %cRed%ERROR: Invalid definition of vimDir: %%j%cSuf%
                    pause
                    popd
                    exit /b 1
                )
            )
        )
    ) else if exist "%PROGRAMFILES%\Vim" (
        set "vimDir=%PROGRAMFILES%\Vim"
        @echo %cYlw%WARNING: vimDir not specified, using !vimDir!%cSuf%
    ) else (
        >&2 echo %cRed%ERROR: Please specify vimDir in file %dirTxt%%cSuf%
        pause
        popd
        exit /b 2
    )
)

if "%vimDir:~-1%" == "\" set "vimDir=%vimDir:~0,-1%"

if not defined vimVer (
    if exist "%verTxt%" (
        for /f "usebackq delims=" %%i in ("%verTxt%") do if not defined vimVer (
            set "vimVer=%%~i"
            if not exist "%vimDir%\!vimVer!" (
                >&2 echo %cRed%ERROR: Invalid definition of vimVer: %%i%cSuf%
                pause
                popd
                exit /b 3
            )
        )
    ) else (
        for /f %%i in ('dir /b /ad /o-d "%vimDir%" 2^>nul') do if not defined vimVer (
            set "vimVer=%%~i"
            echo %cYlw%WARNING: vimVer not specified, using !vimVer!%cSuf%
        )
        if not defined vimVer (
            >&2 echo %cRed%ERROR: Please specify vimVer in file %verTxt%%cSuf%
            >&2 echo %cRed%       For example: vim82%cSuf%
            pause
            popd
            exit /b 4
        )
    )
)

if not defined vimrc set "vimrc=_vimrc"
if not defined myvimrc set "myvimrc=%vimDir%\%vimrc%"
if not defined vimHome set "vimHome=%vimDir%\%vimVer%"

for %%i in ("%vimrc%") do if exist "%%~fi" (
    if exist "%myvimrc%" del "%myvimrc%" || goto UacPrompt
    mklink "%myvimrc%" "%%~fi" || goto UacPrompt
)

for /f %%i in ('dir /b /a-d *.vim 2^>nul') do (
    if exist "%vimHome%\%%~i" del "%vimHome%\%%~i" || goto UacPrompt
    mklink "%vimHome%\%%~i" "%%~fi" || goto UacPrompt
)

for /f %%i in ('dir /b /ad-h 2^>nul') do if not "%%~i" == ".git" (
    pushd "%%~i"
    @echo %cYlw%Entered directory %%~i%cSuf%
    for /f %%j in ('dir /b /a-d *.vim 2^>nul') do (
        if exist "%vimHome%\%%~i\%%~j" del "%vimHome%\%%~i\%%~j" || goto UacPrompt
        mklink "%vimHome%\%%~i\%%~j" "%%~fj" || goto UacPrompt
    )
    popd
)

@echo %cGrn%Completed.%cSuf%
popd
if /i "%~1" NEQ "nopause" pause
exit /b

:uacPrompt
@echo;
@echo     Requesting Administrative Privileges...
@echo     Press YES in UAC Prompt to Continue
@echo;
@>"%TEMP%\UacPrompt.vbs" (
echo Set UAC = CreateObject^("Shell.Application"^)
echo args = "ELEV "
echo For Each strArg in WScript.Arguments
echo args = args ^& strArg ^& " "
echo Next
echo UAC.ShellExecute "%batchname%", args, "%batchfolder%", "runas", 1
)
@cscript //nologo "%TEMP%\UacPrompt.vbs"
@del /f "%TEMP%\UacPrompt.vbs"
@exit /b