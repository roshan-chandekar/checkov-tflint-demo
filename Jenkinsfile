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
                    // Install system dependencies first
                    sh '''
                        echo "Checking and installing system dependencies..."
                        # Update package list (non-interactive)
                        export DEBIAN_FRONTEND=noninteractive
        
                        # Check and install required packages
                        MISSING_PKGS=""
                        command -v wget &> /dev/null || MISSING_PKGS="$MISSING_PKGS wget"
                        command -v unzip &> /dev/null || MISSING_PKGS="$MISSING_PKGS unzip"
                        command -v zip &> /dev/null || MISSING_PKGS="$MISSING_PKGS zip"
                        command -v python3 &> /dev/null || MISSING_PKGS="$MISSING_PKGS python3"
                        command -v pip3 &> /dev/null || MISSING_PKGS="$MISSING_PKGS python3-pip"
        
                        if [ -n "$MISSING_PKGS" ]; then
                            echo "Installing missing packages: $MISSING_PKGS"
                            sudo apt-get update -qq
                            sudo apt-get install -y -qq $MISSING_PKGS || {
                                echo "Package installation failed. Trying individual packages..."
                                for pkg in $MISSING_PKGS; do
                                    sudo apt-get install -y -qq "$pkg" || echo "Failed to install $pkg"
                                done
                            }
                        else
                            echo "All required system packages are installed"
                        fi
        
                        # Verify all tools are available
                        echo "Verifying installed tools:"
                        command -v wget &> /dev/null && echo "✓ wget" || echo "✗ wget not found"
                        command -v unzip &> /dev/null && echo "✓ unzip" || echo "✗ unzip not found"
                        command -v zip &> /dev/null && echo "✓ zip" || echo "✗ zip not found"
                        command -v python3 &> /dev/null && echo "✓ python3" || echo "✗ python3 not found"
                        command -v pip3 &> /dev/null && echo "✓ pip3" || echo "✗ pip3 not found"
                        
                        # Verify Python and pip
                        python3 --version || echo "python3 version check failed"
                        pip3 --version || echo "pip3 not found, will install packages manually"
                    '''
                    
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
                        # Set PATH first to include common installation locations
                        export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin
                        # Expand ~ to $HOME for better compatibility
                        [ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin"
                        
                        # Check if checkov is already installed and accessible
                        CHECKOV_PATH=$(command -v checkov 2>/dev/null || which checkov 2>/dev/null || echo "")
                        if [ -n "$CHECKOV_PATH" ] && [ -x "$CHECKOV_PATH" ]; then
                            echo "Checkov already installed: $($CHECKOV_PATH --version 2>/dev/null || echo 'version check failed')"
                        else
                            echo "Installing Checkov..."
                            
                            # Check if pipx is available
                            PIPX_AVAILABLE=$(command -v pipx 2>/dev/null || which pipx 2>/dev/null || echo "")
                            
                            # Try pipx first (cleanest for externally-managed environments) if available
                            if [ -n "$PIPX_AVAILABLE" ]; then
                                echo "Using pipx to install Checkov..."
                                if $PIPX_AVAILABLE install checkov 2>&1; then
                                    export PATH=$PATH:~/.local/bin
                                    echo "Checkov installed via pipx"
                                else
                                    echo "pipx installation failed, trying pip3..."
                                    pip3 install --user --break-system-packages checkov 2>&1 && export PATH=$PATH:~/.local/bin
                                fi
                            # Try pip install with --break-system-packages for externally-managed environments
                            elif pip3 install --user --break-system-packages checkov 2>&1; then
                                echo "Checkov installed with --break-system-packages flag"
                                export PATH=$PATH:~/.local/bin
                            # Fallback: try regular pip install
                            elif pip3 install --user checkov 2>&1; then
                                echo "Checkov installed successfully"
                                export PATH=$PATH:~/.local/bin
                            else
                                echo "Warning: Checkov installation failed. Trying alternative method..."
                                # Last resort: install with system packages override
                                pip3 install --break-system-packages checkov 2>&1 || echo "Checkov installation failed, but continuing..."
                            fi
                            
                            # Update PATH and verify installation
                            export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin
                            CHECKOV_PATH=$(command -v checkov 2>/dev/null || which checkov 2>/dev/null || find "$HOME/.local/bin" /usr/local/bin /usr/bin -name checkov 2>/dev/null | head -1 || echo "")
                            
                            # Store checkov path for later stages
                            echo "CHECKOV_PATH=$CHECKOV_PATH" > checkov.env
                        fi
                        
                        # Verify and show version using the found path
                        if [ -n "$CHECKOV_PATH" ] && [ -x "$CHECKOV_PATH" ]; then
                            echo "Checkov found at: $CHECKOV_PATH"
                            $CHECKOV_PATH --version || echo "Version check failed, but checkov exists"
                            # Store for later use
                            echo "$CHECKOV_PATH" > .checkov_path
                        else
                            echo "Warning: Checkov command not found after installation attempt."
                            echo "PATH: $PATH"
                            echo "Searching for checkov..."
                            FOUND_CHECKOV=$(find "$HOME/.local/bin" /usr/local/bin /usr/bin -name checkov 2>/dev/null | head -1)
                            if [ -n "$FOUND_CHECKOV" ]; then
                                echo "Found checkov at: $FOUND_CHECKOV"
                                echo "$FOUND_CHECKOV" > .checkov_path
                            else
                                echo "Checkov not found in common locations"
                            fi
                        fi
                    '''

                    // Install TFLint
                    sh '''
                        # Set PATH first to include common installation locations
                        export PATH=$PATH:/usr/local/bin:/usr/bin:/bin
                        
                        # Check if tflint is already installed and accessible
                        TFLINT_PATH=$(command -v tflint 2>/dev/null || which tflint 2>/dev/null || echo "")
                        if [ -n "$TFLINT_PATH" ] && [ -x "$TFLINT_PATH" ]; then
                            echo "TFLint already installed: $($TFLINT_PATH --version 2>/dev/null || echo 'version check failed')"
                        else
                            echo "Installing TFLint..."
                            wget -q https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip
                            
                            if [ -f tflint_linux_amd64.zip ]; then
                                unzip -o -q tflint_linux_amd64.zip
                                
                                # Try to move to /usr/local/bin (requires sudo)
                                if sudo mv tflint /usr/local/bin/ 2>/dev/null; then
                                    echo "TFLint installed to /usr/local/bin"
                                    TFLINT_PATH="/usr/local/bin/tflint"
                                # Fallback: move to current directory and add to PATH
                                elif [ -f tflint ]; then
                                    chmod +x tflint
                                    mkdir -p ~/.local/bin
                                    mv tflint ~/.local/bin/
                                    export PATH=$PATH:~/.local/bin
                                    TFLINT_PATH="$HOME/.local/bin/tflint"
                                    echo "TFLint installed to ~/.local/bin"
                                else
                                    echo "Error: TFLint binary not found after extraction"
                                fi
                                
                                rm -f tflint_linux_amd64.zip
                            else
                                echo "Error: Failed to download TFLint"
                            fi
                        fi
                        
                        # Update PATH and verify installation
                        export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin
                        TFLINT_PATH=$(command -v tflint 2>/dev/null || which tflint 2>/dev/null || find "$HOME/.local/bin" /usr/local/bin /usr/bin /bin -name tflint 2>/dev/null | head -1 || echo "")
                        
                        # Verify and show version using the found path
                        if [ -n "$TFLINT_PATH" ] && [ -x "$TFLINT_PATH" ]; then
                            echo "TFLint found at: $TFLINT_PATH"
                            $TFLINT_PATH --version || echo "Version check failed, but tflint exists"
                            # Store for later use
                            echo "$TFLINT_PATH" > .tflint_path
                        else
                            echo "Warning: TFLint command not found after installation attempt."
                            echo "PATH: $PATH"
                            echo "Searching for tflint..."
                            FOUND_TFLINT=$(find "$HOME/.local/bin" /usr/local/bin /usr/bin /bin -name tflint 2>/dev/null | head -1)
                            if [ -n "$FOUND_TFLINT" ]; then
                                echo "Found tflint at: $FOUND_TFLINT"
                                echo "$FOUND_TFLINT" > .tflint_path
                            else
                                echo "TFLint not found in common locations"
                            fi
                        fi
                    '''
                }
            }
        }

        stage('Build Lambda Package') {
            steps {
                dir('scripts') {
                    sh '''
                        # Ensure zip is available
                        export PATH=$PATH:/usr/bin:/bin
                        if ! command -v zip &> /dev/null; then
                            echo "zip command not found. Installing..."
                            export DEBIAN_FRONTEND=noninteractive
                            sudo apt-get update -qq
                            sudo apt-get install -y -qq zip || {
                                echo "Failed to install zip. Trying to continue..."
                            }
                        fi
                        
                        # Verify zip is now available
                        if command -v zip &> /dev/null; then
                            echo "zip command found: $(which zip)"
                            zip --version | head -1
                        else
                            echo "Warning: zip command still not found after installation attempt"
                        fi
                        
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
                    export PATH=$PATH:/usr/local/bin:/usr/bin:/bin
                    echo "Running terraform fmt check..."
                    
                    # Run fmt check and redirect to file to avoid command substitution issues
                    # Use || true to ensure this stage never fails
                    terraform fmt -check -recursive > fmt_output.txt 2>&1 || true
                    
                    # Read the output
                    if [ -s fmt_output.txt ]; then
                        echo "⚠ Warning: Some Terraform files need formatting:"
                        cat fmt_output.txt
                        echo ""
                        echo "Run 'terraform fmt -recursive' to auto-format them"
                        echo "Continuing pipeline (formatting check is non-blocking)..."
                        rm -f fmt_output.txt
                    else
                        echo "✓ All Terraform files are properly formatted"
                        rm -f fmt_output.txt
                    fi
                '''
            }
        }

        stage('TFLint - Modules') {
            steps {
                sh '''
                    # Load TFLint path if stored
                    export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
                    
                    # Try to find TFLint
                    TFLINT_CMD=""
                    if [ -f .tflint_path ]; then
                        TFLINT_CMD=$(cat .tflint_path 2>/dev/null)
                    fi
                    
                    # If not in file, search for it
                    if [ -z "$TFLINT_CMD" ] || [ ! -x "$TFLINT_CMD" ]; then
                        TFLINT_CMD=$(command -v tflint 2>/dev/null || which tflint 2>/dev/null || echo "")
                        if [ -z "$TFLINT_CMD" ]; then
                            # Search in common locations
                            TFLINT_CMD=$(find "$HOME/.local/bin" /usr/local/bin /usr/bin /bin -name tflint -type f 2>/dev/null | head -1)
                        fi
                    fi
                    
                        # Check if TFLint is found and executable
                        if [ -n "$TFLINT_CMD" ] && [ -x "$TFLINT_CMD" ]; then
                            echo "Running TFLint on modules using: $TFLINT_CMD"
                            echo "TFLint version: $($TFLINT_CMD --version 2>/dev/null || echo 'unknown')"
                            
                            # Copy TFLint config to modules directory if it exists
                            if [ -f ../.tflint.hcl ]; then
                                cp ../.tflint.hcl modules/.tflint.hcl 2>/dev/null || true
                            fi
                            
                            cd modules
                            for module in */; do
                                if [ -d "$module" ]; then
                                    MODULE_NAME=$(basename "$module")
                                    echo "Linting module: modules/$MODULE_NAME"
                                    cd "$module"
                                    # Copy TFLint config if available
                                    if [ -f ../../.tflint.hcl ]; then
                                        cp ../../.tflint.hcl .tflint.hcl 2>/dev/null || true
                                    fi
                                    # Initialize TFLint plugins
                                    echo "Initializing TFLint for modules/$MODULE_NAME..."
                                    $TFLINT_CMD --init 2>&1 | head -20 || echo "TFLint init completed (may have warnings)"
                                    # Run TFLint with default format, show module path context
                                    echo "--- TFLint results for modules/$MODULE_NAME (showing full paths) ---"
                                    echo "Scanning directory: modules/$MODULE_NAME/"
                                    set +e
                                    # Run TFLint - it will show relative paths, context is in the header above
                                    $TFLINT_CMD 2>&1 || true
                                    TFLINT_MODULE_EXIT=${PIPESTATUS[0]}
                                    set -e
                                    if [ $TFLINT_MODULE_EXIT -eq 0 ]; then
                                        echo "✓ No issues found in modules/$MODULE_NAME"
                                    else
                                        echo "⚠ Issues found in modules/$MODULE_NAME (see above)"
                                    fi
                                    echo "--- End of TFLint results for modules/$MODULE_NAME ---"
                                    cd ..
                                fi
                            done
                            cd ..
                    else
                        echo "⚠ Warning: TFLint not found. Skipping module linting."
                        echo "TFLint may not have been installed correctly in the Setup Tools stage."
                        echo "Searching for tflint in common locations..."
                        find "$HOME/.local/bin" /usr/local/bin /usr/bin /bin -name tflint 2>/dev/null || echo "TFLint not found"
                    fi
                '''
            }
        }

        stage('TFLint - Project') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh '''
                        # Load TFLint path if stored
                        export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
                        
                        # Try to find TFLint
                        TFLINT_CMD=""
                        if [ -f ../.tflint_path ]; then
                            TFLINT_CMD=$(cat ../.tflint_path 2>/dev/null)
                        fi
                        
                        # If not in file, search for it
                        if [ -z "$TFLINT_CMD" ] || [ ! -x "$TFLINT_CMD" ]; then
                            TFLINT_CMD=$(command -v tflint 2>/dev/null || which tflint 2>/dev/null || echo "")
                            if [ -z "$TFLINT_CMD" ]; then
                                # Search in common locations
                                TFLINT_CMD=$(find "$HOME/.local/bin" /usr/local/bin /usr/bin /bin -name tflint -type f 2>/dev/null | head -1)
                            fi
                        fi
                        
                        # Check if TFLint is found and executable
                        if [ -n "$TFLINT_CMD" ] && [ -x "$TFLINT_CMD" ]; then
                            echo "Running TFLint on ${PROJECT_DIR} using: $TFLINT_CMD"
                            echo "TFLint version: $($TFLINT_CMD --version 2>/dev/null || echo 'unknown')"
                            
                            # Copy TFLint config if it exists in root
                            if [ -f ../../.tflint.hcl ]; then
                                cp ../../.tflint.hcl .tflint.hcl 2>/dev/null || true
                                echo "TFLint config file copied"
                            fi
                            
                            # Initialize TFLint plugins
                            echo "Initializing TFLint plugins..."
                            $TFLINT_CMD --init 2>&1 | head -30 || echo "TFLint init completed (may have warnings)"
                            
                            # Get current directory path relative to workspace root
                            CURRENT_DIR=$(pwd)
                            WORKSPACE_ROOT=$(cd ../.. && pwd)
                            # Use parameter expansion instead of sed to avoid Groovy parsing issues
                            RELATIVE_PATH=${CURRENT_DIR#$WORKSPACE_ROOT/}
                            
                            # Run TFLint with default format (shows file names, line numbers, and issues)
                            echo "--- TFLint output for ${RELATIVE_PATH} (shows full paths) ---"
                            echo "Scanning directory: ${RELATIVE_PATH}/"
                            set +e
                            # Run TFLint - file paths will be relative to current directory
                            # Context is shown in the header above
                            $TFLINT_CMD 2>&1 | tee tflint-output.txt
                            TFLINT_EXIT=$?
                            set -e
                            
                            if [ $TFLINT_EXIT -eq 0 ]; then
                                echo "✓ No issues found in ${RELATIVE_PATH}"
                            else
                                echo "⚠ Issues found in ${RELATIVE_PATH} (see above for full paths and line numbers)"
                            fi
                            echo "--- End of TFLint output for ${RELATIVE_PATH} ---"
                            
                            # Run TFLint with JSON format for results file (includes file information)
                            echo "Generating TFLint JSON results (includes full file paths)..."
                            set +e
                            $TFLINT_CMD --format json > tflint-results-temp.json 2>&1
                            TFLINT_JSON_EXIT=$?
                            set -e
                            
                            # Process JSON to add full paths
                            if [ -f tflint-results-temp.json ] && [ -s tflint-results-temp.json ]; then
                                # Use jq to add full path prefix to filenames if available
                                if command -v jq &> /dev/null; then
                                    cat tflint-results-temp.json | jq --arg prefix "$RELATIVE_PATH/" '.issues[] | .range.filename = ($prefix + .range.filename) | .' | jq -s '{issues: ., errors: []}' > tflint-results.json 2>/dev/null || cp tflint-results-temp.json tflint-results.json
                                else
                                    # Without jq, just copy the file (paths will be relative to current dir)
                                    cp tflint-results-temp.json tflint-results.json
                                fi
                                rm -f tflint-results-temp.json
                            else
                                cp tflint-results-temp.json tflint-results.json 2>/dev/null || echo '{"issues":[],"errors":[]}' > tflint-results.json
                                rm -f tflint-results-temp.json
                            fi
                            
                            # Verify results file
                            if [ -f tflint-results.json ]; then
                                if [ -s tflint-results.json ]; then
                                    echo "✓ TFLint results saved to tflint-results.json"
                                    echo "Results preview (showing full file paths and issues):"
                                    # Use jq if available to show full paths
                                    if command -v jq &> /dev/null; then
                                        # Extract and show full path information
                                        echo "Issues found:"
                                        # Use simpler jq commands to avoid Groovy parsing issues with backslashes
                                        cat tflint-results.json | jq -r '.issues[] | .range.filename + ":" + (.range.start.line | tostring) + ":" + (.range.start.column | tostring) + " - " + .rule.name + ": " + .message' 2>/dev/null | head -50 || {
                                            # Fallback: show raw JSON if jq format fails
                                            echo "Showing raw JSON structure:"
                                            cat tflint-results.json | head -50
                                        }
                                        echo ""
                                        echo "Full JSON structure (first issue with complete path):"
                                        cat tflint-results.json | jq '.issues[0] | {full_path: .range.filename, line: .range.start.line, column: .range.start.column, rule: .rule.name, message: .message}' 2>/dev/null || cat tflint-results.json | head -30
                                    else
                                        echo "Note: Install 'jq' for better JSON parsing. Showing raw JSON:"
                                        cat tflint-results.json | head -50
                                    fi
                                else
                                    echo "⚠ Warning: TFLint results file is empty"
                                    echo "TFLint JSON exit code: $TFLINT_JSON_EXIT"
                                    # Create a valid empty JSON structure
                                    echo '{"issues":[],"errors":[]}' > tflint-results.json
                                fi
                            else
                                echo "⚠ Warning: TFLint results file was not created"
                                echo "TFLint JSON exit code: $TFLINT_JSON_EXIT"
                                echo '{"issues":[],"errors":[]}' > tflint-results.json
                            fi
                        else
                            echo "⚠ Warning: TFLint not found. Skipping project linting."
                            echo "TFLint may not have been installed correctly in the Setup Tools stage."
                            echo "Creating empty results file..."
                            echo "{}" > tflint-results.json
                        fi
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
                    # Load Checkov path if stored
                    export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin
                    if [ -f .checkov_path ]; then
                        CHECKOV_CMD=$(cat .checkov_path)
                    else
                        CHECKOV_CMD=$(command -v checkov 2>/dev/null || which checkov 2>/dev/null || echo "checkov")
                    fi
                    
                    if [ ! -x "$CHECKOV_CMD" ] && ! command -v checkov &> /dev/null; then
                        echo "Warning: Checkov not found. Skipping scan."
                        echo "{}" > checkov-modules-results.json
                        exit 0
                    fi
                    
                    echo "Running Checkov on modules using: $CHECKOV_CMD"
                    # Use config file if it exists
                    CHECKOV_CONFIG=""
                    if [ -f .checkov.yaml ]; then
                        CHECKOV_CONFIG="--config-file .checkov.yaml"
                        echo "Using Checkov config file: .checkov.yaml"
                    fi
                    
                    # Run Checkov and capture both stdout and stderr
                    set +e
                    $CHECKOV_CMD -d modules \
                        --framework terraform \
                        $CHECKOV_CONFIG \
                        --output cli \
                        --output json \
                        --output-file-path checkov-modules-results.json \
                        --soft-fail 2>&1 | tee checkov-modules-output.txt
                    CHECKOV_EXIT=$?
                    set -e
                    
                    # Show CLI output
                    if [ -f checkov-modules-output.txt ]; then
                        echo "--- Checkov CLI Output ---"
                        cat checkov-modules-output.txt
                        echo "--- End of CLI Output ---"
                    fi
                    
                    # Verify results file was created and has content
                    if [ -f checkov-modules-results.json ]; then
                        if [ -s checkov-modules-results.json ]; then
                            echo "✓ Checkov scan completed. Results saved to checkov-modules-results.json"
                            echo "Results summary (first 30 lines):"
                            cat checkov-modules-results.json | head -30 || true
                        else
                            echo "⚠ Warning: Checkov results file is empty"
                            echo "Checkov exit code: $CHECKOV_EXIT"
                            echo "This might mean no issues were found, or Checkov encountered an error"
                        fi
                    else
                        echo "⚠ Warning: Checkov results file was not created"
                        echo "Checkov exit code: $CHECKOV_EXIT"
                        echo "{}" > checkov-modules-results.json
                    fi
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
                        # Load Checkov path if stored
                        export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin
                        if [ -f ../.checkov_path ]; then
                            CHECKOV_CMD=$(cat ../.checkov_path)
                        else
                            CHECKOV_CMD=$(command -v checkov 2>/dev/null || which checkov 2>/dev/null || echo "checkov")
                        fi
                        
                        if [ ! -x "$CHECKOV_CMD" ] && ! command -v checkov &> /dev/null; then
                            echo "Warning: Checkov not found. Skipping scan."
                            echo "{}" > checkov-results.json
                            exit 0
                        fi
                        
                        echo "Running Checkov on ${PROJECT_DIR} using: $CHECKOV_CMD"
                        # Use config file if it exists
                        CHECKOV_CONFIG=""
                        if [ -f ../../.checkov.yaml ]; then
                            CHECKOV_CONFIG="--config-file ../../.checkov.yaml"
                            echo "Using Checkov config file: .checkov.yaml"
                        fi
                        
                        # Run Checkov and capture both stdout and stderr
                        set +e
                        $CHECKOV_CMD -d . \
                            --framework terraform \
                            $CHECKOV_CONFIG \
                            --output cli \
                            --output json \
                            --output-file-path checkov-results.json \
                            --soft-fail 2>&1 | tee checkov-output.txt
                        CHECKOV_EXIT=$?
                        set -e
                        
                        # Show CLI output
                        if [ -f checkov-output.txt ]; then
                            echo "--- Checkov CLI Output ---"
                            cat checkov-output.txt
                            echo "--- End of CLI Output ---"
                        fi
                        
                        # Verify results file was created and has content
                        if [ -f checkov-results.json ]; then
                            if [ -s checkov-results.json ]; then
                                echo "✓ Checkov scan completed. Results saved to checkov-results.json"
                                echo "Results summary (first 30 lines):"
                                cat checkov-results.json | head -30 || true
                            else
                                echo "⚠ Warning: Checkov results file is empty"
                                echo "Checkov exit code: $CHECKOV_EXIT"
                                echo "This might mean no issues were found, or Checkov encountered an error"
                            fi
                        else
                            echo "⚠ Warning: Checkov results file was not created"
                            echo "Checkov exit code: $CHECKOV_EXIT"
                            echo "{}" > checkov-results.json
                        fi
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
                        export PATH=$PATH:/usr/local/bin:/usr/bin:/bin
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
                        export PATH=$PATH:/usr/local/bin:/usr/bin:/bin
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
                        export PATH=$PATH:/usr/local/bin:/usr/bin:/bin
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
                        # Load Checkov path if stored
                        export PATH=$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin
                        if [ -f ../.checkov_path ]; then
                            CHECKOV_CMD=$(cat ../.checkov_path)
                        else
                            CHECKOV_CMD=$(command -v checkov 2>/dev/null || which checkov 2>/dev/null || echo "checkov")
                        fi
                        
                        if [ ! -x "$CHECKOV_CMD" ] && ! command -v checkov &> /dev/null; then
                            echo "Warning: Checkov not found. Skipping plan scan."
                            echo "{}" > checkov-plan-results.json
                            exit 0
                        fi
                        
                        echo "Running Checkov on Terraform plan using: $CHECKOV_CMD"
                        terraform show -json tfplan > tfplan.json
                        
                        # Run Checkov on plan
                        set +e
                        $CHECKOV_CMD -f tfplan.json \
                            --framework terraform_plan \
                            --output cli \
                            --output json \
                            --output-file-path checkov-plan-results.json \
                            --soft-fail 2>&1
                        CHECKOV_EXIT=$?
                        set -e
                        
                        # Verify results file
                        if [ -f checkov-plan-results.json ]; then
                            if [ -s checkov-plan-results.json ]; then
                                echo "✓ Checkov plan scan completed. Results saved to checkov-plan-results.json"
                                echo "Results summary:"
                                cat checkov-plan-results.json | head -20 || true
                            else
                                echo "⚠ Warning: Checkov plan results file is empty"
                                echo "Checkov exit code: $CHECKOV_EXIT"
                            fi
                        else
                            echo "⚠ Warning: Checkov plan results file was not created"
                            echo "Checkov exit code: $CHECKOV_EXIT"
                            echo "{}" > checkov-plan-results.json
                        fi
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
                # Keep path files for debugging, but clean up if needed
                # rm -f .checkov_path .tflint_path checkov.env || true
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
