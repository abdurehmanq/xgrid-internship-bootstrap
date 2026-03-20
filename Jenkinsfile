pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                // Grabs the code from your GitHub branch
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                // Navigate to the API folder and build the image
                dir('python-health-api') {
                    sh 'docker build -t sre-health-api:jenkins-build .'
                }
            }
        }

       stage('Test API Endpoint') {
            steps {
                // Run the container
                sh 'docker run -d --name api-test-run -p 8082:8080 sre-health-api:jenkins-build'
                sh 'sleep 5' // Give the Python app a few seconds to boot up
                
                // The SRE Fix: Dynamically grab the container's internal IP address
                sh '''
                    API_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' api-test-run)
                    echo "The API container is running at IP: $API_IP"
                    curl -f http://$API_IP:8080/health || exit 1
                '''
            }
        }
    }
    
    post {
        always {
            // SRE Best Practice: Always clean up the test container, even if the build fails
            sh 'docker stop api-test-run || true'
            sh 'docker rm api-test-run || true'
        }
    }
}
