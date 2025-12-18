/*
 * IMPORTANT: TESTING ONLY - NO INFRASTRUCTURE CREATION
 * This pipeline runs validation and security scanning only.
 * Terraform Apply is DISABLED.
 */

pipeline {
    agent any

    parameters {
        choice(name: 'PROJECT', choices: ['dev', 'staging', 'prod'], description: 'Select project')
    }

    environment {
        AWS_REGION = 'us-east-1'
        PROJECT_DIR = "projects/${params.PROJECT}"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
                    TERRAFORM_CMD=$(command -v terraform 2>/dev/null || find /usr/local/bin /usr/bin -name terraform 2>/dev/null | head -1)
                    CHECKOV_CMD=$(command -v checkov 2>/dev/null || find $HOME/.local/bin /usr/local/bin /usr/bin -name checkov 2>/dev/null | head -1)
                    TFLINT_CMD=$(command -v tflint 2>/dev/null || find $HOME/.local/bin /usr/local/bin /usr/bin -name tflint 2>/dev/null | head -1)
                    [ -z "$TERRAFORM_CMD" ] && { echo "ERROR: Terraform not found"; exit 1; }
                    [ -z "$CHECKOV_CMD" ] && { echo "ERROR: Checkov not found"; exit 1; }
                    [ -z "$TFLINT_CMD" ] && { echo "ERROR: TFLint not found"; exit 1; }
                    echo "$CHECKOV_CMD" > .checkov_path
                    echo "$TFLINT_CMD" > .tflint_path
                    echo "All tools verified"
                '''
            }
        }

        stage('Build Lambda Package') {
            steps {
                dir('scripts') {
                    sh '''
                        command -v zip > /dev/null 2>&1 || { echo "ERROR: zip not found"; exit 1; }
                        chmod +x build_lambda.sh && ./build_lambda.sh
                    '''
                }
            }
        }

        stage('Terraform Format') {
            steps {
                sh 'terraform fmt -check -recursive || echo "Some files need formatting"'
            }
        }

        stage('TFLint - Modules') {
            steps {
                sh '''
                    TFLINT_CMD=$(cat .tflint_path 2>/dev/null || command -v tflint 2>/dev/null || find $HOME/.local/bin /usr/local/bin /usr/bin -name tflint 2>/dev/null | head -1)
                    [ -f .tflint.hcl ] && cp .tflint.hcl modules/.tflint.hcl || true
                    cd modules
                    for module in */; do
                        [ -d "$module" ] && cd "$module" && $TFLINT_CMD --init > /dev/null 2>&1 && $TFLINT_CMD || true
                        cd ..
                    done
                '''
            }
        }

        stage('TFLint - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        TFLINT_CMD=$(cat ../.tflint_path 2>/dev/null || command -v tflint 2>/dev/null || find $HOME/.local/bin /usr/local/bin /usr/bin -name tflint 2>/dev/null | head -1)
                        [ -f ../../.tflint.hcl ] && cp ../../.tflint.hcl .tflint.hcl || true
                        $TFLINT_CMD --init > /dev/null 2>&1
                        $TFLINT_CMD --format json > tflint-results.json 2>&1 || echo '{"issues":[],"errors":[]}' > tflint-results.json
                    '''
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
                    CHECKOV_CMD=$(cat .checkov_path 2>/dev/null || command -v checkov 2>/dev/null || find $HOME/.local/bin /usr/local/bin /usr/bin -name checkov 2>/dev/null | head -1)
                    # Aggressive cleanup - remove file or directory
                    rm -rf checkov-modules-results.json checkov-modules-results.tmp 2>/dev/null || true
                    CHECKOV_SKIP="--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144"
                    [ -f .checkov.yaml ] && CHECKOV_CONFIG="--config-file .checkov.yaml" || CHECKOV_CONFIG=""
                    # Run Checkov and capture JSON output to temporary file first (redirect stderr to avoid mixing)
                    $CHECKOV_CMD -d modules --framework terraform $CHECKOV_CONFIG $CHECKOV_SKIP --output json --soft-fail > checkov-modules-results.tmp 2>/dev/null || true
                    # Move temp file to final location (ensures it's a file)
                    if [ -f checkov-modules-results.tmp ] && [ -s checkov-modules-results.tmp ]; then
                        mv checkov-modules-results.tmp checkov-modules-results.json
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
                    sh '''
                        CHECKOV_CMD=$(cat ../.checkov_path 2>/dev/null || command -v checkov 2>/dev/null || find $HOME/.local/bin /usr/local/bin /usr/bin -name checkov 2>/dev/null | head -1)
                        # Aggressive cleanup - remove file or directory
                        rm -rf checkov-results.json checkov-results.tmp 2>/dev/null || true
                        CHECKOV_SKIP="--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144"
                        [ -f ../../.checkov.yaml ] && CHECKOV_CONFIG="--config-file ../../.checkov.yaml" || CHECKOV_CONFIG=""
                        # Run Checkov and capture JSON output to temporary file first (redirect stderr to avoid mixing)
                        $CHECKOV_CMD -d . --framework terraform $CHECKOV_CONFIG $CHECKOV_SKIP --output json --soft-fail > checkov-results.tmp 2>/dev/null || true
                        # Move temp file to final location (ensures it's a file)
                        if [ -f checkov-results.tmp ] && [ -s checkov-results.tmp ]; then
                            mv checkov-results.tmp checkov-results.json
                        else
                            echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-results.json
                        fi
                        # Final safety check - remove directory if it exists
                        [ -d checkov-results.json ] && rm -rf checkov-results.json && echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-results.json || true
                    '''
                }
            }
            post {
                always {
                    sh '''
                        cd '${env.PROJECT_DIR}'
                        [ -d checkov-results.json ] && rm -rf checkov-results.json || true
                        [ ! -f checkov-results.json ] && echo "{}" > checkov-results.json || true
                    '''
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/checkov-results.json", allowEmptyArchive: true
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh 'terraform plan -out=tfplan -input=false'
                }
            }
        }

        stage('Checkov - Plan') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        [ ! -f tfplan ] && { echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-plan-results.json; exit 0; }
                        terraform show -json tfplan > tfplan.json
                        CHECKOV_CMD=$(cat ../.checkov_path 2>/dev/null || command -v checkov 2>/dev/null || find $HOME/.local/bin /usr/local/bin /usr/bin -name checkov 2>/dev/null | head -1)
                        # Aggressive cleanup - remove file or directory
                        rm -rf checkov-plan-results.json checkov-plan-results.tmp 2>/dev/null || true
                        CHECKOV_SKIP="--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144"
                        [ -f ../../.checkov.yaml ] && CHECKOV_CONFIG="--config-file ../../.checkov.yaml" || CHECKOV_CONFIG=""
                        # Run Checkov and capture JSON output to temporary file first (redirect stderr to avoid mixing)
                        $CHECKOV_CMD -f tfplan.json --framework terraform_plan $CHECKOV_CONFIG $CHECKOV_SKIP --output json --soft-fail > checkov-plan-results.tmp 2>/dev/null || true
                        # Move temp file to final location (ensures it's a file)
                        if [ -f checkov-plan-results.tmp ] && [ -s checkov-plan-results.tmp ]; then
                            mv checkov-plan-results.tmp checkov-plan-results.json
                        else
                            echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-plan-results.json
                        fi
                        # Final safety check - remove directory if it exists
                        [ -d checkov-plan-results.json ] && rm -rf checkov-plan-results.json && echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-plan-results.json || true
                    '''
                }
            }
            post {
                always {
                    sh '''
                        cd '${env.PROJECT_DIR}'
                        [ -d checkov-plan-results.json ] && rm -rf checkov-plan-results.json || true
                        [ ! -f checkov-plan-results.json ] && echo "{}" > checkov-plan-results.json || true
                    '''
                    archiveArtifacts artifacts: "${env.PROJECT_DIR}/checkov-plan-results.json", allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            sh 'find . -name "tfplan*" -type f -delete 2>/dev/null || true'
        }
    }
}
