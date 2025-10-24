pipeline {
    agent any

    environment {
        // AWS Configuration
        AWS_ACCOUNT_ID = '462645401353'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'flask-nlp-api'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "build-${env.BUILD_NUMBER}"
        APP_CONTAINER_NAME = 'flask-nlp-app'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo 'Checking out code from GitHub...'
                git branch: 'main', url: 'https://github.com/SriShivahari/Devops_Project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                    
                    // Build the Docker image
                    sh """
                        docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} .
                        docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    """
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    echo "Pushing image to ECR..."
                    
                    sh """
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        # Push with build number tag
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        
                        # Push with latest tag
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                        
                        echo "Successfully pushed image to ECR"
                    """
                }
            }
        }

        stage('Clean Old Images') {
            steps {
                script {
                    echo "Cleaning up old Docker images locally..."
                    
                    sh """
                        # Remove old images to save disk space (keep only last 2)
                        docker images ${ECR_REGISTRY}/${ECR_REPOSITORY} --format "{{.Tag}}" | grep -v latest | tail -n +3 | xargs -I {} docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:{} || true
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    echo "Deploying container ${APP_CONTAINER_NAME}..."
                    
                    sh '''
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        # Pull the latest image
                        echo "Pulling latest image from ECR..."
                        docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                        
                        # Stop and remove old container if it exists
                        echo "Stopping and removing old container if it exists..."
                        if [ $(docker ps -aq -f name=${APP_CONTAINER_NAME}) ]; then
                            docker stop ${APP_CONTAINER_NAME} || true
                            docker rm ${APP_CONTAINER_NAME} || true
                        fi
                        
                        # Start new container
                        echo "Starting new container..."
                        docker run -d \
                            --name ${APP_CONTAINER_NAME} \
                            -p 5000:5000 \
                            --restart unless-stopped \
                            ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                        
                        # Wait for container to be healthy
                        echo "Waiting for container to be healthy..."
                        sleep 10
                        
                        # Check if container is running
                        if [ $(docker ps -q -f name=${APP_CONTAINER_NAME}) ]; then
                            echo "✅ Deployment successful! Container is running."
                            docker ps -f name=${APP_CONTAINER_NAME}
                        else
                            echo "❌ Deployment failed! Container is not running."
                            docker logs ${APP_CONTAINER_NAME}
                            exit 1
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "API is available at: http://<EC2-IP>:5000"
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
