/*
 * ===================================================================
 * IMPORTANT: TESTING ONLY - NO INFRASTRUCTURE CREATION
 * ===================================================================
 * This pipeline is configured for validation and security scanning ONLY.
 * Terraform Apply is DISABLED - no AWS resources will be created.
 * 
 * The pipeline will:
 *   - Run TFLint for linting
 *   - Run Checkov for security scanning
 *   - Validate Terraform configuration
 *   - Create plans (but NOT apply them)
 * 
 * To actually deploy infrastructure, run Terraform commands manually.
 * See .pipeline-note.md for details.
 * ===================================================================
 */

pipeline {
    agent any

    parameters {
        choice(
            name: 'PROJECT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select project to test (NO INFRASTRUCTURE WILL BE CREATED - Testing Only)'
        )
    }

    environment {
        AWS_REGION = 'us-east-1'
        TERRAFORM_VERSION = '1.6.0'
        CHECKOV_VERSION = 'latest'
        TFLINT_VERSION = 'v0.50.0'
        PROJECT_DIR = "projects/${params.PROJECT}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Tools') {
            steps {
                script {
                    // Install Terraform
                    sh '''
                        if command -v terraform &> /dev/null; then
                            echo "Terraform already installed: $(terraform version | head -1)"
                        else
                            echo "Installing Terraform..."
                            wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                            unzip -o -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                            sudo mv terraform /usr/local/bin/ 2>/dev/null || mv terraform /usr/local/bin/
                            rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                            echo "Terraform installed successfully"
                        fi
                        terraform version
                    '''

                    // Install Checkov
                    sh '''
                        if command -v checkov &> /dev/null; then
                            echo "Checkov already installed: $(checkov --version)"
                        else
                            echo "Installing Checkov..."
                            export PATH=$PATH:~/.local/bin
                            
                            # Try pipx first (cleanest for externally-managed environments)
                            if command -v pipx &> /dev/null; then
                                echo "Using pipx to install Checkov..."
                                pipx install checkov
                                export PATH=$PATH:~/.local/bin
                            # Try pip install with --break-system-packages for externally-managed environments
                            elif pip3 install --user --break-system-packages checkov 2>/dev/null; then
                                echo "Checkov installed with --break-system-packages flag"
                            # Fallback: try regular pip install
                            elif pip3 install --user checkov 2>/dev/null; then
                                echo "Checkov installed successfully"
                            else
                                echo "Warning: Checkov installation failed. Trying alternative method..."
                                # Last resort: install with system packages override
                                pip3 install --break-system-packages checkov || echo "Checkov installation failed, but continuing..."
                            fi
                            
                            # Ensure PATH includes local bin directories
                            export PATH=$PATH:~/.local/bin:/usr/local/bin
                        fi
                        
                        # Verify and show version
                        if command -v checkov &> /dev/null; then
                            checkov --version
                        else
                            echo "Warning: Checkov command not found. Some stages may fail."
                            echo "PATH: $PATH"
                        fi
                    '''

                    // Install TFLint
                    sh '''
                        if command -v tflint &> /dev/null; then
                            echo "TFLint already installed: $(tflint --version)"
                        else
                            echo "Installing TFLint..."
                            wget -q https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip
                            unzip -o -q tflint_linux_amd64.zip
                            sudo mv tflint /usr/local/bin/ 2>/dev/null || mv tflint /usr/local/bin/
                            rm -f tflint_linux_amd64.zip
                            echo "TFLint installed successfully"
                        fi
                        tflint --version
                    '''
                }
            }
        }

        stage('Build Lambda Package') {
            steps {
                dir('scripts') {
                    sh '''
                        echo "Building Lambda deployment package..."
                        chmod +x build_lambda.sh
                        ./build_lambda.sh
                    '''
                }
            }
        }

        stage('Terraform Format') {
            steps {
                sh '''
                    echo "Running terraform fmt..."
                    terraform fmt -check -recursive
                '''
            }
        }

        stage('TFLint - Modules') {
            steps {
                sh '''
                    echo "Running TFLint on modules..."
                    cd modules
                    for module in */; do
                        if [ -d "$module" ]; then
                            echo "Linting module: $module"
                            cd "$module"
                            tflint --init || true
                            tflint --format compact || true
                            cd ..
                        fi
                    done
                    cd ..
                '''
            }
        }

        stage('TFLint - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        echo "Running TFLint on ${PROJECT_DIR}..."
                        tflint --init || true
                        tflint --format compact || true
                        tflint --format json > tflint-results.json || true
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/tflint-results.json", allowEmptyArchive: true
                }
            }
        }

        stage('Checkov Security Scan - Modules') {
            steps {
                sh '''
                    echo "Running Checkov on modules..."
                    checkov -d modules \
                        --framework terraform \
                        --output cli \
                        --output json \
                        --output-file-path checkov-modules-results.json \
                        --soft-fail || true
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'checkov-modules-results.json', allowEmptyArchive: true
                }
            }
        }

        stage('Checkov Security Scan - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        echo "Running Checkov on ${PROJECT_DIR}..."
                        checkov -d . \
                            --framework terraform \
                            --output cli \
                            --output json \
                            --output-file-path checkov-results.json \
                            --soft-fail || true
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/checkov-results.json", allowEmptyArchive: true
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        echo "Running terraform init in ${PROJECT_DIR}..."
                        terraform init -input=false
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        echo "Running terraform validate in ${PROJECT_DIR}..."
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        echo "Running terraform plan in ${PROJECT_DIR}..."
                        terraform plan -out=tfplan -input=false
                    '''
                }
            }
        }

        stage('Terraform Plan Security Check') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        echo "Running Checkov on Terraform plan..."
                        terraform show -json tfplan > tfplan.json
                        checkov -f tfplan.json \
                            --framework terraform_plan \
                            --output cli \
                            --output json \
                            --output-file-path checkov-plan-results.json \
                            --soft-fail || true
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/checkov-plan-results.json", allowEmptyArchive: true
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/tfplan.json", allowEmptyArchive: true
                }
            }
        }

        stage('Terraform Apply - DISABLED') {
            when {
                expression { return false }
            }
            steps {
                echo '''
                    ============================================
                    TERRAFORM APPLY IS DISABLED
                    ============================================
                    This pipeline is configured for TESTING ONLY.
                    No infrastructure will be created.
                    Only validation and security scanning will run.
                    ============================================
                '''
            }
        }
    }

    post {
        always {
            sh '''
                echo "Cleaning up temporary files..."
                find . -name "tfplan" -type f -delete || true
                find . -name "tfplan.json" -type f -delete || true
                find . -name "*.zip" -path "*/scripts/*" -prune -o -name "*.zip" -type f -delete || true
            '''
        }
        success {
            echo '''
                ============================================
                Pipeline completed successfully!
                ============================================
                NOTE: This pipeline is for TESTING ONLY.
                No infrastructure was created.
                Review the Checkov and TFLint reports above.
                ============================================
            '''
        }
        failure {
            echo "Pipeline failed. Check the logs for details."
        }
        unstable {
            echo "Pipeline is unstable. Some checks may have failed."
        }
    }
}
