@echo off
cls
odin build . -debug
@REM paths.exe -a a D:\src -a a D:\src\odin b
IF NOT ERRORLEVEL 1 (
    @REM paths.exe -a a test -e a D:\src\odin b
    paths.exe -d odin2
    @REM copy paths.exe C:\software\paths.exe /Y
)