pipeline {
    agent any

    tools {
        nodejs 'NodeJS14'
    }

    environment {
        AWS_REGION = 'us-east-2'
        EKS_CLUSTER = 'microservices-dev-eks'

        ENVIRONMENT = "dev"

        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        FRONTEND_REPO = '${ENVIRONMENT}-ebank-frontend'
        NODE_REPO     = '${ENVIRONMENT}-ebank-node-backend'
        DJANGO_REPO   = '${ENVIRONMENT}-ebank-django-backend'

        K8S_NAMESPACE = 'ebank'

        SONARQUBE_SERVER = 'SonarQube'

        OWASP_THRESHOLD = '7'

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    parameters {
        booleanParam(
            name: 'DEPLOY_TO_EKS',
            defaultValue: true,
            description: 'Deploy images to Amazon EKS'
        )

        booleanParam(
            name: 'PUSH_TO_ECR',
            defaultValue: true,
            description: 'Push Docker images to Amazon ECR'
        )

        booleanParam(
            name: 'RUN_SECURITY_SCANS',
            defaultValue: true,
            description: 'Run OWASP and Trivy security scans'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out E-Bank source code...'
                checkout scm
            }
        }

        stage('Environment Check') {
            steps {
                sh '''
                    echo "======================================"
                    echo "Environment"
                    echo "======================================"

                    node --version || true
                    npm --version || true
                    docker --version
                    aws --version
                    kubectl version --client=true || true
                    trivy --version || true
                '''
            }
        }

        stage('Install Node Dependencies') {
            steps {
                sh '''
                    echo "Installing Node.js dependencies..."
                    npm ci
                '''
            }
        }

        stage('Build Angular Frontend') {
            steps {
                sh '''
                    echo "Building Angular frontend..."

                    node --version
                    npm --version
                    npx ng version

                    npm run build

                    echo "Angular build completed successfully."
                '''
            }
        }

        stage('Django Check') {
            steps {
                sh '''
                    echo "Checking Django application..."

                    if [ -f manage.py ]; then
                        python3 manage.py check
                    else
                        echo "manage.py not found - skipping Django check"
                    fi
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    echo "Running unit tests..."

                    export CHROME_BIN=/usr/bin/google-chrome

                    $CHROME_BIN --version

                    npm test -- \
                        --watch=false \
                        --browsers=ChromeHeadlessNoSandbox \
                        --code-coverage

                    echo "Checking generated coverage..."
                    ls -lh coverage/mean-course/lcov.info
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh '''
                        echo "Running SonarQube analysis..."

                        echo "Checking coverage file..."
                        ls -lh coverage/mean-course/lcov.info

                        echo "Coverage file:"
                        head -20 coverage/mean-course/lcov.info

                        sonar-scanner \
                          -Dsonar.projectKey=ebank \
                          -Dsonar.projectName=E-Bank \
                          -Dsonar.sources=src \
                          -Dsonar.exclusions=node_modules/**,dist/**,coverage/** \
                          -Dsonar.javascript.lcov.reportPaths=coverage/mean-course/lcov.info
                    '''
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('OWASP Dependency Check') {
            when {
                expression {
                    params.RUN_SECURITY_SCANS
                }
            }

            steps {
                withCredentials([
                    string(
                        credentialsId: 'nvd-api-key',
                        variable: 'NVD_API_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "======================================"
                        echo "Running OWASP Dependency-Check..."
                        echo "======================================"

                        rm -rf "$WORKSPACE/dependency-check-report"
                        mkdir -p "$WORKSPACE/dependency-check-report"

                        echo "Dependency-Check version:"
                        dependency-check.sh --version

                        echo "Running Dependency-Check..."

                        dependency-check.sh \
                            --project "E-Bank" \
                            --scan "$WORKSPACE" \
                            --format HTML \
                            --format XML \
                            --out "$WORKSPACE/dependency-check-report" \
                            --data /var/lib/jenkins/dependency-check-data \
                            --nvdApiKey "$NVD_API_KEY" \
                            --disableYarnAudit \
                            --disableOssIndex \
                            --disableAssembly

                        echo "OWASP Dependency-Check completed."
                        echo "Vulnerabilities are reported but do not block the pipeline."
                    '''

                    archiveArtifacts(
                        artifacts: 'dependency-check-report/*',
                        allowEmptyArchive: false
                    )
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            when {
                expression {
                    params.RUN_SECURITY_SCANS
                }
            }

            steps {
                sh '''
                    echo "Running Trivy filesystem scan..."

                    trivy fs \
                        --scanners vuln,secret,misconfig \
                        --skip-dirs node_modules \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        .

                    echo "Trivy filesystem scan completed."
                    echo "Findings are reported but do not block the pipeline."
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    echo "Building Docker images..."

                    docker build \
                        -f Dockerfile.frontend \
                        -t ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} \
                        -t ${ECR_REGISTRY}/${FRONTEND_REPO}:latest \
                        .

                    docker build \
                        -f Dockerfile.node \
                        -t ${ECR_REGISTRY}/${NODE_REPO}:${IMAGE_TAG} \
                        -t ${ECR_REGISTRY}/${NODE_REPO}:latest \
                        .

                    docker build \
                        -f Dockerfile.django \
                        -t ${ECR_REGISTRY}/${DJANGO_REPO}:${IMAGE_TAG} \
                        -t ${ECR_REGISTRY}/${DJANGO_REPO}:latest \
                        .
                '''
            }
        }

        stage('Trivy Docker Image Scan') {
            when {
                expression {
                    params.RUN_SECURITY_SCANS
                }
            }

            steps {
                sh '''
                    echo "Scanning Docker images..."

                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --ignore-unfixed \
                        ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}

                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --ignore-unfixed \
                        ${ECR_REGISTRY}/${NODE_REPO}:${IMAGE_TAG}

                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --ignore-unfixed \
                        ${ECR_REGISTRY}/${DJANGO_REPO}:${IMAGE_TAG}
                '''
            }
        }

        stage('ECR Login') {
            when {
                expression {
                    params.PUSH_TO_ECR
                }
            }

            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-ecr-credentials']
                ]) {
                    sh '''
                        echo "Logging into Amazon ECR..."

                        aws ecr get-login-password \
                            --region ${AWS_REGION} | \
                        docker login \
                            --username AWS \
                            --password-stdin \
                            ${ECR_REGISTRY}
                    '''
                }
            }
        }

        stage('Push Images to ECR') {
            when {
                expression {
                    params.PUSH_TO_ECR
                }
            }

            steps {
                sh '''
                    echo "Pushing images to ECR..."

                    docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${NODE_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${DJANGO_REPO}:${IMAGE_TAG}

                    docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:latest
                    docker push ${ECR_REGISTRY}/${NODE_REPO}:latest
                    docker push ${ECR_REGISTRY}/${DJANGO_REPO}:latest
                '''
            }
        }

        stage('Configure EKS') {
            when {
                expression {
                    params.DEPLOY_TO_EKS
                }
            }

            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-ecr-credentials']
                ]) {
                    sh '''
                        echo "Configuring kubectl for EKS..."

                        aws eks update-kubeconfig \
                            --region ${AWS_REGION} \
                            --name ${EKS_CLUSTER}

                        kubectl cluster-info
                        kubectl get nodes
                    '''
                }
            }
        }

        stage('Create Kubernetes Namespace') {
            when {
                expression {
                    params.DEPLOY_TO_EKS
                }
            }

            steps {
                sh '''
                    kubectl create namespace ${K8S_NAMESPACE} \
                        --dry-run=client \
                        -o yaml | kubectl apply -f -
                '''
            }
        }

        stage('Deploy to EKS') {
            when {
                expression {
                    params.DEPLOY_TO_EKS
                }
            }

            steps {
                sh '''
                    echo "Deploying E-Bank to EKS..."

                    kubectl apply \
                        -f k8s/ \
                        -n ${K8S_NAMESPACE}

                    kubectl set image deployment/ebank-frontend \
                        ebank-frontend=${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}

                    kubectl set image deployment/ebank-node \
                        ebank-node=${ECR_REGISTRY}/${NODE_REPO}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}

                    kubectl set image deployment/ebank-django \
                        ebank-django=${ECR_REGISTRY}/${DJANGO_REPO}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}
                '''
            }
        }

        stage('Verify Deployment') {
            when {
                expression {
                    params.DEPLOY_TO_EKS
                }
            }

            steps {
                sh '''
                    echo "Checking Kubernetes resources..."

                    kubectl get pods -n ${K8S_NAMESPACE}
                    kubectl get deployments -n ${K8S_NAMESPACE}
                    kubectl get services -n ${K8S_NAMESPACE}

                    echo "Checking rollouts..."

                    kubectl rollout status \
                        deployment/ebank-frontend \
                        -n ${K8S_NAMESPACE} \
                        --timeout=5m

                    kubectl rollout status \
                        deployment/ebank-node \
                        -n ${K8S_NAMESPACE} \
                        --timeout=5m

                    kubectl rollout status \
                        deployment/ebank-django \
                        -n ${K8S_NAMESPACE} \
                        --timeout=5m
                '''
            }
        }
    }

    post {
        success {
            echo '''
            ============================================
            E-BANK CI/CD SUCCESS
            ============================================
            Docker images built
            Security checks completed
            Images pushed to ECR
            Application deployed to EKS
            Kubernetes rollout successful
            ============================================
            '''
        }

        failure {
            echo '''
            ============================================
            E-BANK CI/CD FAILED
            ============================================
            Check the failed Jenkins stage.
            ============================================
            '''
        }

        always {
            echo "Cleaning Jenkins workspace..."
            cleanWs()
        }
    }
}
