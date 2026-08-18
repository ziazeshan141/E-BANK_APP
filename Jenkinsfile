pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
    }

    environment {

        // =====================================================
        // AWS
        // =====================================================
        AWS_REGION = 'us-east-2'
        EKS_CLUSTER = 'microservices-dev-eks'

        // Set this in Jenkins or replace with your AWS account ID
        AWS_ACCOUNT_ID = credentials('aws-account-id')

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        // =====================================================
        // ECR repositories
        // =====================================================
        FRONTEND_REPO = 'ebank-frontend'
        NODE_REPO     = 'ebank-node'
        DJANGO_REPO   = 'ebank-django'

        // =====================================================
        // Kubernetes
        // =====================================================
        K8S_NAMESPACE = 'ebank'

        // =====================================================
        // SonarQube
        // =====================================================
        SONARQUBE_SERVER = 'SonarQube'

        // =====================================================
        // Security
        // =====================================================
        OWASP_THRESHOLD = '7'

        // =====================================================
        // Docker image tag
        // =====================================================
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

        // =====================================================
        // 1. CHECKOUT
        // =====================================================

        stage('Checkout') {

            steps {

                echo 'Checking out E-Bank source code...'

                checkout scm
            }
        }


        // =====================================================
        // 2. ENVIRONMENT CHECK
        // =====================================================

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


        // =====================================================
        // 3. INSTALL BACKEND DEPENDENCIES
        // =====================================================

        stage('Install Node Dependencies') {

            steps {

                dir('') {

                    sh '''
                        echo "Installing Node.js dependencies..."

                        npm ci
                    '''
                }
            }
        }


        // =====================================================
        // 4. FRONTEND BUILD
        // =====================================================

        stage('Build Angular Frontend') {

            steps {

                sh '''
                    echo "Building Angular frontend..."

                    NODE_OPTIONS=--openssl-legacy-provider npm run build -- --configuration=production
                '''
            }
        }


        // =====================================================
        // 5. DJANGO CHECK
        // =====================================================

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


        // =====================================================
        // 6. UNIT TESTS
        // =====================================================

        stage('Unit Tests') {

            steps {

                sh '''
                    echo "Running unit tests..."
                    export CHROME_BIN=/usr/bin/google-chrome
                    export NODE_OPTIONS=--openssl-legacy-provider

                    echo "Chrome version:"
                    $CHROME_BIN --version

                    npm test -- --watch=false --browsers=ChromeHeadlessNoSandbox
                '''
            }
        }


        // =====================================================
        // 7. SONARQUBE ANALYSIS
        // =====================================================

        stage('SonarQube Analysis') {

            steps {

                withSonarQubeEnv("${SONARQUBE_SERVER}") {

                    sh '''
                        echo "Running SonarQube analysis..."

                        sonar-scanner \
                          -Dsonar.projectKey=ebank \
                          -Dsonar.projectName=E-Bank \
                          -Dsonar.sources=. \
                          -Dsonar.exclusions=node_modules/**,dist/**,coverage/**
                    '''
                }
            }
        }


        // =====================================================
        // 8. SONARQUBE QUALITY GATE
        // =====================================================

        stage('SonarQube Quality Gate') {

            steps {

                timeout(time: 5, unit: 'MINUTES') {

                    waitForQualityGate abortPipeline: true
                }
            }
        }


        // =====================================================
        // 9. OWASP DEPENDENCY CHECK
        // =====================================================

        stage('OWASP Dependency Check') {

            when {

                expression {
                    params.RUN_SECURITY_SCANS
                }
            }

            steps {

                sh '''
                    echo "Running OWASP Dependency-Check..."

                    dependency-check.sh \
                        --project "E-Bank" \
                        --scan . \
                        --format HTML \
                        --format XML \
                        --out dependency-check-report \
                        --failOnCVSS ${OWASP_THRESHOLD} || true
                '''

                archiveArtifacts artifacts:
                    'dependency-check-report/*',
                    allowEmptyArchive: true
            }
        }


        // =====================================================
        // 10. TRIVY FILESYSTEM SCAN
        // =====================================================

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
                        --exit-code 1 \
                        .
                '''
            }
        }


        // =====================================================
        // 11. DOCKER BUILD
        // =====================================================

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


        // =====================================================
        // 12. TRIVY DOCKER IMAGE SCAN
        // =====================================================

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
                        --exit-code 1 \
                        --ignore-unfixed \
                        ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}

                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --ignore-unfixed \
                        ${ECR_REGISTRY}/${NODE_REPO}:${IMAGE_TAG}

                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --ignore-unfixed \
                        ${ECR_REGISTRY}/${DJANGO_REPO}:${IMAGE_TAG}
                '''
            }
        }


        // =====================================================
        // 13. LOGIN TO AWS ECR
        // =====================================================

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


        // =====================================================
        // 14. PUSH TO ECR
        // =====================================================

        stage('Push Images to ECR') {

            when {

                expression {
                    params.PUSH_TO_ECR
                }
            }

            steps {

                sh '''
                    echo "Pushing images to ECR..."

                    docker push \
                        ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}

                    docker push \
                        ${ECR_REGISTRY}/${NODE_REPO}:${IMAGE_TAG}

                    docker push \
                        ${ECR_REGISTRY}/${DJANGO_REPO}:${IMAGE_TAG}

                    docker push \
                        ${ECR_REGISTRY}/${FRONTEND_REPO}:latest

                    docker push \
                        ${ECR_REGISTRY}/${NODE_REPO}:latest

                    docker push \
                        ${ECR_REGISTRY}/${DJANGO_REPO}:latest
                '''
            }
        }


        // =====================================================
        // 15. EKS CONFIGURATION
        // =====================================================

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


        // =====================================================
        // 16. KUBERNETES NAMESPACE
        // =====================================================

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


        // ======================================================
        // 17. DEPLOY TO EKS
        // ======================================================

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
                        -n ${K8S_NAMESPACE} || true

                    kubectl set image deployment/ebank-node \
                        ebank-node=${ECR_REGISTRY}/${NODE_REPO}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE} || true

                    kubectl set image deployment/ebank-django \
                        ebank-django=${ECR_REGISTRY}/${DJANGO_REPO}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE} || true
                '''
            }
        }


        // =====================================================
        // 18. ROLLOUT VERIFICATION
        // =====================================================

        stage('Verify Deployment') {

            when {

                expression {
                    params.DEPLOY_TO_EKS
                }
            }

            steps {

                sh '''
                    echo "Checking Kubernetes resources..."

                    kubectl get pods \
                        -n ${K8S_NAMESPACE}

                    kubectl get deployments \
                        -n ${K8S_NAMESPACE}

                    kubectl get services \
                        -n ${K8S_NAMESPACE}

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


    // =========================================================
    // POST ACTIONS
    // =========================================================

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
