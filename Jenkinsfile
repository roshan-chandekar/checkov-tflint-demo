pipeline {
    agent any

    options { timestamps() }

    stages {

        stage('Checkout') {
            steps { checkout scm }
        }

        stage('TFLint Scan') {
            steps {
                sh '''
set +e
rm -f tflint.txt tflint.json || true

docker run --rm \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  ghcr.io/terraform-linters/tflint:latest \
  tflint --init

# Then run lint
docker run --rm \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  ghcr.io/terraform-linters/tflint:latest \
  --format json > tflint.json

docker run --rm \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  ghcr.io/terraform-linters/tflint:latest \
  --format compact | tee tflint.txt
'''
            }
        }

        stage('tfsec Scan') {
            steps {
                sh '''
set +e
rm -f tfsec.txt tfsec.json || true

docker run --rm \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  liamg/tfsec:latest \
  --format json --out tfsec.json | tee tfsec.txt
'''
            }
        }

        stage('Checkov Scan') {
            steps {
                sh '''
set +e
rm -f checkov.txt checkov.json || true

docker run --rm \
  --user $(id -u):$(id -g) \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  bridgecrew/checkov:latest \
  -d . \
  --framework terraform \
  -o cli -o json \
  --output-file-path checkov.json | tee checkov.txt
'''
            }
        }

        stage('Post or Update PR Comment') {
            when { expression { env.CHANGE_ID != null } }
            steps {
                withCredentials([
                    string(credentialsId: 'roshan-chandekar', variable: 'GITHUB_TOKEN')
                ]) {
                    sh '''
set -e

OWNER=$(echo "$GIT_URL" | sed -E 's#.*/([^/]+)/([^/.]+)(\\.git)?#\\1#')
REPO=$(echo "$GIT_URL" | sed -E 's#.*/([^/]+)/([^/.]+)(\\.git)?#\\2#')
PR=$CHANGE_ID

# -------------------
# Parse summaries
# -------------------
TFLINT_SUMMARY=$(cat tflint.txt || true)
TFSEC_SUMMARY=$(cat tfsec.txt || true)
CHECKOV_SUMMARY=$(grep -E "Passed checks:|Failed checks:|Skipped checks:" checkov.txt || true)

# -------------------
# Build PR comment
# -------------------
COMMENT=$(cat <<EOF
### 🔍 Terraform Scan Results

Repository: $REPO
PR: #$PR
Commit: $GIT_COMMIT

**TFLint Summary:**
$TFLINT_SUMMARY

**tfsec Summary:**
$TFSEC_SUMMARY

**Checkov Summary:**
$CHECKOV_SUMMARY

**TFLint JSON:**
$(cat tflint.json | sed 's/^/    /')

**tfsec JSON:**
$(cat tfsec.json | sed 's/^/    /')

**Checkov JSON:**
$(cat checkov.json | sed 's/^/    /')

Full CLI output available in Jenkins build logs
EOF
)

EXISTING_COMMENT_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/$OWNER/$REPO/issues/$PR/comments \
  | jq -r '.[] | select(.body | contains("### 🔍 Terraform Scan Results")) | .id' | head -n1)

if [ -n "$EXISTING_COMMENT_ID" ]; then
    curl -s -X PATCH \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/$OWNER/$REPO/issues/comments/$EXISTING_COMMENT_ID \
      -d "$(jq -n --arg body "$COMMENT" '{body: $body}')"
else
    curl -s -X POST \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/$OWNER/$REPO/issues/$PR/comments \
      -d "$(jq -n --arg body "$COMMENT" '{body: $body}')"
fi
'''
                }
            }
        }

    }

    post {
        success { echo "✅ Terraform scans (TFLint, tfsec, Checkov) completed and PR comment updated" }
    }
}
