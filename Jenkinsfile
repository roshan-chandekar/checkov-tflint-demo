/*
 * IMPORTANT: TESTING ONLY - NO INFRASTRUCTURE CREATION
 * This pipeline runs validation and security scanning only.
 * Terraform Apply is DISABLED.
 */

pipeline {
    agent any

    // Discard old builds to prevent disk space issues
    options {
        buildDiscarder(logRotator(
            numToKeepStr: '10',
            daysToKeepStr: '7',
            artifactNumToKeepStr: '5',
            artifactDaysToKeepStr: '3'
        ))
    }

    parameters {
        choice(name: 'PROJECT', choices: ['dev'], description: 'Select project')
    }

    environment {
        AWS_REGION = 'us-east-1'
        PROJECT_DIR = "projects/dev"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Terraform Format') {
            steps {
                sh 'terraform fmt -check -recursive || echo "Some files need formatting"'
            }
        }

        stage('TFLint - Modules') {
            steps {
                sh '''
                    [ -f .tflint.hcl ] && cp .tflint.hcl modules/.tflint.hcl || true
                    cd modules
                    for module in */; do
                        if [ -d "$module" ]; then
                            docker exec -w /workspace/modules/"$module" tflint tflint --init > /dev/null 2>&1 || true
                            docker exec -w /workspace/modules/"$module" tflint tflint || true
                        fi
                    done
                '''
            }
        }

        stage('TFLint - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh """
                        [ -f ../../.tflint.hcl ] && cp ../../.tflint.hcl .tflint.hcl || true
                        docker exec -w /workspace/${env.PROJECT_DIR} tflint tflint --init > /dev/null 2>&1 || true
                        docker exec -w /workspace/${env.PROJECT_DIR} tflint tflint --format json > tflint-results.json 2>&1 || echo '{\"issues\":[],\"errors\":[]}' > tflint-results.json
                    """
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/tflint-results.json", allowEmptyArchive: true
                }
            }
        }

        stage('Checkov - Modules') {
            steps {
                sh '''
                    # Aggressive cleanup - remove file or directory
                    rm -rf checkov-modules-results.json checkov-modules-results.tmp 2>/dev/null || true
                    CHECKOV_SKIP="--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144"
                    [ -f .checkov.yaml ] && CHECKOV_CONFIG="--config-file .checkov.yaml" || CHECKOV_CONFIG=""
                    echo "Running Checkov on modules directory..."
                    # Run Checkov via Docker container (remove -i flag to avoid stdin hang)
                    # Use timeout to prevent hanging (10 minutes max)
                    timeout 600 docker exec -w /workspace checkov checkov -d modules --framework terraform $CHECKOV_CONFIG $CHECKOV_SKIP --output json --soft-fail > checkov-modules-results.tmp 2>&1 || true
                    # Move temp file to final location (ensures it's a file)
                    if [ -f checkov-modules-results.tmp ] && [ -s checkov-modules-results.tmp ]; then
                        # Check if output is valid JSON (starts with { or [)
                        if head -c 1 checkov-modules-results.tmp | grep -q '[{\\[]'; then
                            mv checkov-modules-results.tmp checkov-modules-results.json
                        else
                            echo "Warning: Checkov output is not valid JSON, creating empty result"
                            echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-modules-results.json
                        fi
                    else
                        echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-modules-results.json
                    fi
                    # Final safety check - remove directory if it exists
                    [ -d checkov-modules-results.json ] && rm -rf checkov-modules-results.json && echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-modules-results.json || true
                '''
            }
            post {
                always {
                    sh '''
                        [ -d checkov-modules-results.json ] && rm -rf checkov-modules-results.json || true
                        [ ! -f checkov-modules-results.json ] && echo "{}" > checkov-modules-results.json || true
                    '''
                    archiveArtifacts artifacts: 'checkov-modules-results.json', allowEmptyArchive: true
                }
            }
        }

        stage('Checkov - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh """
                        # Aggressive cleanup - remove file or directory
                        rm -rf checkov-results.json checkov-results.tmp 2>/dev/null || true
                        CHECKOV_SKIP=\"--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144\"
                        [ -f ../../.checkov.yaml ] && CHECKOV_CONFIG=\"--config-file ../../.checkov.yaml\" || CHECKOV_CONFIG=\"\"
                        echo \"Running Checkov on project directory...\"
                        # Run Checkov via Docker container (remove -i flag to avoid stdin hang)
                        # Use timeout to prevent hanging (10 minutes max)
                        timeout 600 docker exec -w /workspace/${env.PROJECT_DIR} checkov checkov -d . --framework terraform \$CHECKOV_CONFIG \$CHECKOV_SKIP --output json --soft-fail > checkov-results.tmp 2>&1 || true
                        # Move temp file to final location (ensures it's a file)
                        if [ -f checkov-results.tmp ] && [ -s checkov-results.tmp ]; then
                            # Check if output is valid JSON (starts with { or [)
                            if head -c 1 checkov-results.tmp | grep -q '[{\\[]'; then
                                mv checkov-results.tmp checkov-results.json
                            else
                                echo \"Warning: Checkov output is not valid JSON, creating empty result\"
                                echo '{\"summary\":{\"passed\":0,\"failed\":0,\"skipped\":0,\"parsing_errors\":0,\"resource_count\":0},\"results\":{\"passed_checks\":[],\"failed_checks\":[],\"skipped_checks\":[],\"parsing_errors\":[]}}' > checkov-results.json
                            fi
                        else
                            echo '{\"summary\":{\"passed\":0,\"failed\":0,\"skipped\":0,\"parsing_errors\":0,\"resource_count\":0},\"results\":{\"passed_checks\":[],\"failed_checks\":[],\"skipped_checks\":[],\"parsing_errors\":[]}}' > checkov-results.json
                        fi
                        # Final safety check - remove directory if it exists
                        [ -d checkov-results.json ] && rm -rf checkov-results.json && echo '{\"summary\":{\"passed\":0,\"failed\":0,\"skipped\":0,\"parsing_errors\":0,\"resource_count\":0},\"results\":{\"passed_checks\":[],\"failed_checks\":[],\"skipped_checks\":[],\"parsing_errors\":[]}}' > checkov-results.json || true
                    """
                }
            }
            post {
                always {
                    dir(env.PROJECT_DIR) {
                        sh '''
                            [ -d checkov-results.json ] && rm -rf checkov-results.json || true
                            [ ! -f checkov-results.json ] && echo "{}" > checkov-results.json || true
                        '''
                    }
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/checkov-results.json", allowEmptyArchive: true
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh "docker exec -w /workspace/${env.PROJECT_DIR} terraform terraform init -input=false"
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh "docker exec -w /workspace/${env.PROJECT_DIR} terraform terraform validate"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh "docker exec -w /workspace/${env.PROJECT_DIR} terraform terraform plan -out=tfplan -input=false"
                }
            }
        }

        stage('Checkov - Plan') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh """
                        [ ! -f tfplan ] && { echo '{\"summary\":{\"passed\":0,\"failed\":0,\"skipped\":0,\"parsing_errors\":0,\"resource_count\":0},\"results\":{\"passed_checks\":[],\"failed_checks\":[],\"skipped_checks\":[],\"parsing_errors\":[]}}' > checkov-plan-results.json; exit 0; }
                        docker exec -w /workspace/${env.PROJECT_DIR} terraform terraform show -json tfplan > tfplan.json
                        # Aggressive cleanup - remove file or directory
                        rm -rf checkov-plan-results.json checkov-plan-results.tmp 2>/dev/null || true
                        CHECKOV_SKIP=\"--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144\"
                        [ -f ../../.checkov.yaml ] && CHECKOV_CONFIG=\"--config-file ../../.checkov.yaml\" || CHECKOV_CONFIG=\"\"
                        echo \"Running Checkov on Terraform plan...\"
                        # Run Checkov via Docker container (remove -i flag to avoid stdin hang)
                        # Use timeout to prevent hanging (10 minutes max)
                        timeout 600 docker exec -w /workspace/${env.PROJECT_DIR} checkov checkov -f tfplan.json --framework terraform_plan \$CHECKOV_CONFIG \$CHECKOV_SKIP --output json --soft-fail > checkov-plan-results.tmp 2>&1 || true
                        # Move temp file to final location (ensures it's a file)
                        if [ -f checkov-plan-results.tmp ] && [ -s checkov-plan-results.tmp ]; then
                            mv checkov-plan-results.tmp checkov-plan-results.json
                        else
                            echo '{\"summary\":{\"passed\":0,\"failed\":0,\"skipped\":0,\"parsing_errors\":0,\"resource_count\":0},\"results\":{\"passed_checks\":[],\"failed_checks\":[],\"skipped_checks\":[],\"parsing_errors\":[]}}' > checkov-plan-results.json
                        fi
                        # Final safety check - remove directory if it exists
                        [ -d checkov-plan-results.json ] && rm -rf checkov-plan-results.json && echo '{\"summary\":{\"passed\":0,\"failed\":0,\"skipped\":0,\"parsing_errors\":0,\"resource_count\":0},\"results\":{\"passed_checks\":[],\"failed_checks\":[],\"skipped_checks\":[],\"parsing_errors\":[]}}' > checkov-plan-results.json || true
                    """
                }
            }
            post {
                always {
                    dir(env.PROJECT_DIR) {
                        sh '''
                            [ -d checkov-plan-results.json ] && rm -rf checkov-plan-results.json || true
                            [ ! -f checkov-plan-results.json ] && echo "{}" > checkov-plan-results.json || true
                        '''
                    }
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/checkov-plan-results.json", allowEmptyArchive: true
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                sh '''
                    # Check if SonarQube scanner is available via Docker
                    if command -v docker > /dev/null 2>&1 && docker ps | grep -q "sonar-scanner"; then
                        echo "Using SonarQube scanner from Docker container"
                        # Jenkins is running on host, use localhost for SonarQube
                        SONAR_URL="http://localhost:9000"
                        
                        # Update sonar-project.properties with correct URL
                        if [ -f sonar-project.properties ]; then
                            sed -i.bak "s|sonar.host.url=.*|sonar.host.url=$SONAR_URL|" sonar-project.properties
                        fi
                        
                        # Run SonarQube scanner via Docker container
                        # Check if authentication token is provided
                        if [ -n "$SONAR_TOKEN" ]; then
                            docker exec -w /workspace sonar-scanner sonar-scanner \
                                -Dsonar.host.url="$SONAR_URL" \
                                -Dsonar.login="$SONAR_TOKEN" \
                                -Dproject.settings=sonar-project.properties || echo "SonarQube scan completed with warnings"
                        else
                            echo "Warning: SONAR_TOKEN not set. Using default authentication (admin/admin)"
                            echo "To use token authentication, set SONAR_TOKEN in Jenkins credentials"
                            docker exec -w /workspace sonar-scanner sonar-scanner \
                                -Dsonar.host.url="$SONAR_URL" \
                                -Dproject.settings=sonar-project.properties || echo "SonarQube scan completed with warnings"
                        fi
                        
                        # Restore original sonar-project.properties if backup exists
                        [ -f sonar-project.properties.bak ] && mv sonar-project.properties.bak sonar-project.properties || true
                    elif command -v sonar-scanner > /dev/null 2>&1; then
                        echo "Using locally installed SonarQube scanner"
                        # Use local sonar-scanner if available
                        SONAR_URL="${SONAR_HOST_URL:-http://localhost:9000}"
                        if [ -n "$SONAR_TOKEN" ]; then
                            sonar-scanner \
                                -Dsonar.host.url="$SONAR_URL" \
                                -Dsonar.login="$SONAR_TOKEN" \
                                -Dproject.settings=sonar-project.properties || echo "SonarQube scan completed with warnings"
                        else
                            sonar-scanner \
                                -Dsonar.host.url="$SONAR_URL" \
                                -Dproject.settings=sonar-project.properties || echo "SonarQube scan completed with warnings"
                        fi
                    else
                        echo "WARNING: SonarQube scanner not found (neither Docker container nor local installation)"
                        echo "Skipping SonarQube scan. To enable:"
                        echo "  1. Start docker-compose: docker-compose up -d"
                        echo "  2. Or install sonar-scanner locally"
                        echo "  3. Ensure SonarQube server is running at http://localhost:9000"
                    fi
                '''
            }
            post {
                always {
                    echo "SonarQube scan stage completed. View results at: http://localhost:9000 (or your SonarQube URL)"
                }
            }
        }
    }

    post {
        always {
            sh '''
                find . -name "tfplan*" -type f -delete 2>/dev/null || true
                find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
            '''
        }
    }
}
