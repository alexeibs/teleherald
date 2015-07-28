@echo off

echo --- Build tests.exe ---
dub build -b unittest -c unittests
if ERRORLEVEL 1 goto build_error

echo --- Run tests with coverage ---
if exist "%~dp0coverage" (
  rmdir "%~dp0coverage" /s /q
)

opencppcoverage --sources "%~dp0source" --export_type "html:%~dp0coverage" tests.exe

echo --- Finished ---
exit /b 0

:build_error
echo --- BUILD FAILED ---