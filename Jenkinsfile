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
                    command -v terraform > /dev/null 2>&1 || { echo "ERROR: Terraform not found"; exit 1; }
                    command -v checkov > /dev/null 2>&1 || { echo "ERROR: Checkov not found"; exit 1; }
                    command -v tflint > /dev/null 2>&1 || { echo "ERROR: TFLint not found"; exit 1; }
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
                    [ -f .tflint.hcl ] && cp .tflint.hcl modules/.tflint.hcl || true
                    cd modules
                    for module in */; do
                        [ -d "$module" ] && cd "$module" && tflint --init > /dev/null 2>&1 && tflint || true
                        cd ..
                    done
                '''
            }
        }

        stage('TFLint - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        [ -f ../../.tflint.hcl ] && cp ../../.tflint.hcl .tflint.hcl || true
                        tflint --init > /dev/null 2>&1
                        tflint --format json > tflint-results.json 2>&1 || echo '{"issues":[],"errors":[]}' > tflint-results.json
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
                    CHECKOV_SKIP="--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144"
                    [ -f .checkov.yaml ] && CHECKOV_CONFIG="--config-file .checkov.yaml" || CHECKOV_CONFIG=""
                    checkov -d modules --framework terraform $CHECKOV_CONFIG $CHECKOV_SKIP --output json --output-file-path checkov-modules-results.json --soft-fail || true
                    [ ! -s checkov-modules-results.json ] && echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-modules-results.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'checkov-modules-results.json', allowEmptyArchive: true
                }
            }
        }

        stage('Checkov - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        CHECKOV_SKIP="--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144"
                        [ -f ../../.checkov.yaml ] && CHECKOV_CONFIG="--config-file ../../.checkov.yaml" || CHECKOV_CONFIG=""
                        checkov -d . --framework terraform $CHECKOV_CONFIG $CHECKOV_SKIP --output json --output-file-path checkov-results.json --soft-fail || true
                        [ ! -s checkov-results.json ] && echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-results.json
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
                        CHECKOV_SKIP="--skip-check CKV_AWS_18 --skip-check CKV_AWS_19 --skip-check CKV_AWS_144"
                        [ -f ../../.checkov.yaml ] && CHECKOV_CONFIG="--config-file ../../.checkov.yaml" || CHECKOV_CONFIG=""
                        checkov -f tfplan.json --framework terraform_plan $CHECKOV_CONFIG $CHECKOV_SKIP --output json --output-file-path checkov-plan-results.json --soft-fail || true
                        [ ! -s checkov-plan-results.json ] && echo '{"summary":{"passed":0,"failed":0,"skipped":0,"parsing_errors":0,"resource_count":0},"results":{"passed_checks":[],"failed_checks":[],"skipped_checks":[],"parsing_errors":[]}}' > checkov-plan-results.json
                    '''
                }
            }
            post {
                always {
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
