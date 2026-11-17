
@echo off
setlocal

echo ==========================================
echo JPetStore Performance Test Execution
echo ==========================================

REM JMeter installation
set "JMETER_HOME=D:\D_Drive\Performance tools\apache-jmeter-5.6.3"
set "JMETER=%JMETER_HOME%\bin\jmeter.bat"

REM Project directory
set "PROJECT_DIR=%~dp0.."

REM Test plan
set "TEST_PLAN=%PROJECT_DIR%\test-plans\01_Browse_Product_Catalog.jmx"

REM Generate unique execution ID
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "RUN_ID=%%I"

REM Output directories
set "RESULT_DIR=%PROJECT_DIR%\results\%RUN_ID%"
set "REPORT_DIR=%PROJECT_DIR%\reports\%RUN_ID%"
set "LOG_DIR=%PROJECT_DIR%\logs"

set "RESULT_FILE=%RESULT_DIR%\catalog-results.jtl"
set "REPORT_FILE=%REPORT_DIR%"
set "LOG_FILE=%LOG_DIR%\catalog-%RUN_ID%.log"

REM Validate JMeter
if not exist "%JMETER%" (
    echo ERROR: JMeter not found: %JMETER%
    exit /b 1
)

REM Validate test plan
if not exist "%TEST_PLAN%" (
    echo ERROR: Test plan not found: %TEST_PLAN%
    exit /b 1
)

REM Check JPetStore availability
echo Checking JPetStore application...

powershell -NoProfile -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:8081/jpetstore/' -UseBasicParsing -TimeoutSec 10; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"

if errorlevel 1 (
    echo ERROR: JPetStore is not responding at localhost:8081
    exit /b 1
)

REM Create output directories
if not exist "%RESULT_DIR%" mkdir "%RESULT_DIR%"
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo.
echo Test Plan: %TEST_PLAN%
echo Results:   %RESULT_FILE%
echo Report:    %REPORT_FILE%
echo Log:       %LOG_FILE%
echo.

REM Execute JMeter in non-GUI mode
call "%JMETER%" -n -t "%TEST_PLAN%" -l "%RESULT_FILE%" -j "%LOG_FILE%" -e -o "%REPORT_DIR%"

set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo SUCCESS: JMeter execution completed.
    echo HTML Report: %REPORT_DIR%\index.html
) else (
    echo ERROR: JMeter execution failed with exit code %EXIT_CODE%.
)

echo ==========================================

exit /b %EXIT_CODE%
