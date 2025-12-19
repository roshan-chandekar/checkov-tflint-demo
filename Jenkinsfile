pipeline {
    agent any

    environment {
        TF_DIR = "."
    }

    stages {

        stage('Checkout Terraform Repo') {
            steps {
                checkout scm
            }
        }

        stage('TFLint') {
            steps {
                script {
                    docker.image('ghcr.io/terraform-linters/tflint:latest').inside('--entrypoint=""') {
                        sh """
                          cd ${TF_DIR}
                          tflint --init
                          tflint
                        """
                    }
                }
            }
        }

        stage('tfsec') {
            steps {
                script {
                    docker.image('aquasec/tfsec:latest').inside('--entrypoint=""') {
                        sh """
                          cd ${TF_DIR}
                          tfsec .
                        """
                    }
                }
            }
        }

        stage('Checkov') {
            steps {
                script {
                    docker.image('bridgecrew/checkov:latest').inside('--entrypoint=""') {
                        sh """
                          cd ${TF_DIR}
                          checkov -d .
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Terraform validation passed (tflint, tfsec, checkov)"
        }
        failure {
            echo "❌ Terraform validation failed"
        }
    }
}
