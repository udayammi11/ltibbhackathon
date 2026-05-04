pipeline {
    agent any
    environment {
      scannerHome = tool 'sonar';
    }
    stages{
        stage ("code") {
            steps{
                git 'https://github.com/udayammi11/ltibbhackathon.git'
            }
        }
        stage ('sonar') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=MyProject"
                }
            }
        }
        /*
        stage ('QualityGates') {
            steps {
                waitForQualityGate abortPipeline: false, credentialsId: 'sonar'
            }
        }
        */
        stage ('image') {
            steps {
            sh 'docker build -t dbimage database'
            sh 'docker build -t appimage .'
        }
        }
         stage ('trivy') {
            steps {
            sh 'trivy image dbimage'
            sh 'trivy image appimage '
        }
        }
         stage ('tag') {
            steps {
            sh 'docker tag dbimage udayammi11/ud:db'
            sh 'docker tag  appimage udayammi11/ud:fe'
        }
        }
        stage ('push') {
            steps {
                script {
                withDockerRegistry(credentialsId: 'dockercreds') {
                    sh 'docker push udayammi11/ud:db'
                    sh 'docker push udayammi11/ud:fe'
                }
                }
            }
        }
        stage ('deploy') {
            steps {
                sh 'docker run -d --name mysqldb -p 3306:3306 udayammi11/ud:db'
                sh 'docker run -d --name myapp -p 3000:80 --link mysqldb udayammi11/ud:fe'
            }
        }
    }
}
