@echo off

for /f "tokens=1 delims=," %%i in ('whoami /groups /FO CSV /NH') do (
    if "%%~i"=="BUILTIN\Administrators" set ADMIN=yes
    if "%%~i"=="Mandatory Label\High Mandatory Level" set ELEVATED=yes
)

if "%ADMIN%" neq "yes" (
    goto runas
)

if "%ELEVATED%" neq "yes" (
    goto runas
)

:admins
    mklink C:%HOMEPATH%\.bashrc             %~d0%~p0.bashrc
    mklink C:%HOMEPATH%\.bash_profile       %~d0%~p0.bash_profile
    mklink C:%HOMEPATH%\.vimrc              %~d0%~p0.vimrc
    mklink C:%HOMEPATH%\.gitconfig          %~d0%~p0.gitconfig
    mklink C:%HOMEPATH%\.eslintrc           %~d0%~p0.eslintrc
    mklink C:%HOMEPATH%\.minttyrc           %~d0%~p0.minttyrc
    mklink C:%HOMEPATH%\.ctrlp-launcher     %~d0%~p0.ctrlp-launcher
    mklink C:%HOMEPATH%\.nyagos             %~d0%~p0.nyagos

    goto exit1

:runas
    powershell -Command Start-Process -Verb runas "%0"

:exit1
