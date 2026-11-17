
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        JMETER_HOME = 'D:\\D_Drive\\Performance tools\\apache-jmeter-5.6.3'
        APP_URL = 'http://localhost:8081/jpetstore/'
        TEST_PLAN = 'test-plans\\01_Browse_Product_Catalog.jmx'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo 'Repository checkout completed.'
            }
        }

        stage('Validate Environment') {
            steps {
                bat '''
                    if not exist "%JMETER_HOME%\\bin\\jmeter.bat" (
                        echo ERROR: JMeter installation not found.
                        exit /b 1
                    )

                    if not exist "%TEST_PLAN%" (
                        echo ERROR: JMeter test plan not found.
                        exit /b 1
                    )
                '''

                powershell '''
                    try {
                        $response = Invoke-WebRequest `
                            -Uri $env:APP_URL `
                            -UseBasicParsing `
                            -TimeoutSec 10

                        if ($response.StatusCode -ne 200) {
                            throw "JPetStore returned HTTP $($response.StatusCode)"
                        }

                        Write-Host "JPetStore is available."
                    }
                    catch {
                        Write-Error "JPetStore health check failed: $_"
                        exit 1
                    }
                '''
            }
        }

        stage('Execute JMeter Test') {
            steps {
                bat '''
                    if not exist results mkdir results
                    if not exist reports mkdir reports
                    if not exist logs mkdir logs

                    if exist "results\\catalog-%BUILD_NUMBER%.jtl" (
                        del "results\\catalog-%BUILD_NUMBER%.jtl"
                    )

                    if exist "reports\\catalog-%BUILD_NUMBER%" (
                        rmdir /s /q "reports\\catalog-%BUILD_NUMBER%"
                    )

                    call "%JMETER_HOME%\\bin\\jmeter.bat" ^
                        -n ^
                        -t "%TEST_PLAN%" ^
                        -l "results\\catalog-%BUILD_NUMBER%.jtl" ^
                        -j "logs\\catalog-%BUILD_NUMBER%.log" ^
                        -e ^
                        -o "reports\\catalog-%BUILD_NUMBER%"

                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Verify Report') {
            steps {
                bat '''
                    if not exist "reports\\catalog-%BUILD_NUMBER%\\index.html" (
                        echo ERROR: HTML dashboard was not generated.
                        exit /b 1
                    )

                    echo HTML dashboard generated successfully.
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'results/*.jtl, reports/**/*.html, reports/**/*.css, reports/**/*.js, reports/**/*.json, reports/**/*.png, reports/**/*.csv, logs/*.log',
                             allowEmpty: true
        }

        success {
            echo 'JPetStore performance test completed successfully.'
        }

        failure {
            echo 'JPetStore performance pipeline failed. Check the console output and logs.'
        }
    }
}
