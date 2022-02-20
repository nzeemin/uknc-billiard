@echo off
set rt11exe=C:\bin\rt11\rt11.exe

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "DATESTAMP=%YYYY%-%MM%-%DD%"
for /f %%i in ('git rev-list HEAD --count') do (set REVISION=%%i)
echo Rev.%REVISION% %DATESTAMP%

echo VERSTR:	.ASCIZ "Rev.%REVISION% %DATESTAMP%" > VERSIO.MAC

@if exist BILLIB.LST del BILLIB.LST
@if exist BILLIB.OBJ del BILLIB.OBJ
@if exist BILLIA.MAC del BILLIA.MAC
@if exist BILLIA.OBJ del BILLIA.OBJ
@if exist BILLIA.SAV del BILLIA.SAV
@if exist BILLIA.MAP del BILLIA.MAP

%rt11exe% MACRO/LIST:DK: BILLIB.MAC

for /f "delims=" %%a in ('findstr /B "Errors detected" BILLIB.LST') do set "errdet=%%a"
if "%errdet%"=="Errors detected:  0" (
  echo COMPILED SUCCESSFULLY
) ELSE (
  findstr /RC:"^[ABDEILMNOPQRTUZ] " BILLIB.LST
  echo ======= %errdet% =======
  exit /b
)

%rt11exe% RU PASSIM BILLIA,BILLIA=BILLIA.PAS

set errdet=
for /f "delims=" %%a in ('findstr /B "ERRORS DETECTED" BILLIA.LST') do set "errdet=%%a"
if "%errdet%"=="ERRORS DETECTED:  0    " (
  rem echo BILLIA.PAS COMPILED SUCCESSFULLY
) ELSE (
REM  findstr /RC:"^****** " BILLIA.LST
  echo ======= BILLIA.PAS NOT COMPILED =======
  exit /b
)

%rt11exe% MACRO/LIST:DK: BILLIA.MAC

for /f "delims=" %%a in ('findstr /B "Errors detected" BILLIA.LST') do set "errdet=%%a"
if "%errdet%"=="Errors detected:  0" (
  echo COMPILED SUCCESSFULLY
) ELSE (
  findstr /RC:"^[ABDEILMNOPQRTUZ] " BILLIA.LST
  echo ======= %errdet% =======
  exit /b
)

%rt11exe% LINK/STACK:1000 BILLIA,BILLIB,PASFIS /MAP:BILLIA.MAP

for /f "delims=" %%a in ('findstr /B "Undefined globals" BILLIA.MAP') do set "undefg=%%a"
if "%undefg%"=="" (
  type BILLIA.MAP
  echo.
  echo %ESCchar%[92mLINKED SUCCESSFULLY%ESCchar%[0m
) ELSE (
  echo %ESCchar%[91m======= LINK FAILED =======%ESCchar%[0m
  exit /b
)
