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
                // Run the container on port 8082 (since Jenkins is using 8080)
                sh 'docker run -d --name api-test-run -p 8082:8080 sre-health-api:jenkins-build'
                sh 'sleep 5' // Give the Python app a few seconds to boot up
                
                // Test the health endpoint. If it fails, the pipeline turns red.
                sh 'curl -f http://localhost:8082/health || exit 1'
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
