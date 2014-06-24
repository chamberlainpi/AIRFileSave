@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

set AIR_TARGET=native
set OUTPUT_EXT=exe
set OPTIONS=-tsa none
::set SIGNING_OPTIONS=-storetype pkcs12 -keystore bat\myCert.pfx -keypass pi3rr3cert 
call bat\Packager.bat

pause