@echo off
set rt11dsk=C:\bin\rt11dsk

if exist x-ukncbtl\BILLIA.BIN del x-ukncbtl\BILLIA.BIN
rem D:\Work\MyProjects\ukncbtl-utils\Release\Sav2Cart.exe BILLIA.SAV BILLIA.BIN
rem move BILLIA.BIN x-ukncbtl\BILLIA.BIN

del x-ukncbtl\billiard.dsk
@if exist "x-ukncbtl\billiard.dsk" (
  echo.
  echo ####### FAILED to delete old disk image file #######
  exit /b
)
copy x-ukncbtl\sys1002ex.dsk billiard.dsk
%rt11dsk% a billiard.dsk BILLIA.SAV
move billiard.dsk x-ukncbtl\billiard.dsk

@if not exist "x-ukncbtl\billiard.dsk" (
  echo ####### ERROR disk image file not found #######
  exit /b
)

start x-ukncbtl\UKNCBTL.exe /boot
