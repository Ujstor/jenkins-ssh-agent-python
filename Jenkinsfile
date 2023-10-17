pipeline {
    agent any

    environment {
        GITHUB_USER = ''
        GITHUB_REPO = ''
        DOCKER_HUB_USERNAME = ''
        DOCKER_REPO_NAME = ''
        VERSION_PART = 'Patch' // Patch, Minor, Major
        TAG = ''
    }

    stages {
        stage('Checkout Code') {
            steps {
                git(url: 'https://github.com/${GITHUB_USER}/${GITHUB_REPO}/', branch: env.BRANCH_NAME)
            }
        }

        stage('Test') {
            steps {
                script {
                    sh "/home/jenkins/pytest.sh ${WORKSPACE}"
                }
            }
        }

        stage('Generate Docker Image Tag') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                script {
                    TAG = sh(script: "/home/jenkins/docker_tag.sh $DOCKER_HUB_USERNAME $DOCKER_REPO_NAME $VERSION_PART", returnStdout: true).trim()

                    if (TAG) {
                        echo "Docker image tag generated successfully: $TAG"
                    } else {
                        error "Failed to generate Docker image tag"
                    }

                    env.TAG = TAG
                }
            }
        }

        stage('Build') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                script {
                    sh "docker build --no-cache -t ${DOCKER_HUB_USERNAME}/${DOCKER_REPO_NAME}:${TAG} ."
                }
            }
        }

        stage('Docker Login') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                script {

                    def dockerCredentialsId = 'be9636c4-b828-41af-ad0b-46d4182dfb06'

                    withCredentials([usernamePassword(credentialsId: dockerCredentialsId, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                script {
                    sh "docker push ${DOCKER_HUB_USERNAME}/${DOCKER_REPO_NAME}:${TAG}"
                }
            }
        }

        stage('Environment Cleanup') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                script {
                    sh "docker rmi ${DOCKER_HUB_USERNAME}/${DOCKER_REPO_NAME}:${TAG}"
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully"
        }
    }
}