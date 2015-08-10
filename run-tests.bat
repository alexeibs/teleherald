@echo off

echo --- Build tests.exe ---
dub build -b unittest -c unittests %*
if ERRORLEVEL 1 goto build_error

echo --- Run tests without coverage ---
build\tests.exe
if ERRORLEVEL 1 goto tests_failed

echo --- Run tests with coverage ---
if exist "%~dp0coverage" (
  rmdir "%~dp0coverage" /s /q
)

opencppcoverage --sources "%~dp0source" --modules %~dp0 --export_type "html:%~dp0coverage" build\tests.exe

echo --- Finished ---
exit /b 0

:build_error
echo --- BUILD FAILED ---
exit /b 1

:tests_failed
echo --- TESTS FAILED ---
exit /b 1
