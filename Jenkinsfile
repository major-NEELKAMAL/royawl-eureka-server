pipeline {
  agent any

  triggers {
    githubPush()
  }

  environment {
    MAVEN_REPO = "/var/lib/jenkins/.m2/repository"
    DEPLOY_PATH = "/home/ubuntu/jar/jenkins/deploy"
    REMOTE_IP = "168.231.102.240"
    SSH_CRED_ID = "vps-ssh-key"   
    SSH_USER = "root"
    APP_NAME = "royawl-eureka-server"
    IMAGE_NAME = "royawl-eureka-server:latest"
    IMAGE_TAR = "royawl-eureka-server.tar"
  }

  stages {
    stage('Production Guard') {
      when {
        anyOf {
          branch 'master'
          expression { env.GIT_BRANCH == 'origin/master' }
          triggeredBy 'UserIdCause'
        }
      }
      stages {
        stage('Prepare') {
          steps {
            checkout scm
          }
        }

        stage('Build') {
          steps {
            
            dir('.') {
              sh 'mvn clean package -DskipTests -Dmaven.repo.local=$MAVEN_REPO'
            }
          }
        }

        stage('Docker Image Create') {
          steps {
            script {

              sh "docker buildx build --platform linux/amd64 -t ${IMAGE_NAME} ."

              sh "docker save ${IMAGE_NAME} -o ${IMAGE_TAR}"
            }
          }
        }

         stage('Upload Docker Image') {
          steps {
             sshagent(credentials: ["${env.SSH_CRED_ID}"]) {
              sh "scp -o StrictHostKeyChecking=no ${IMAGE_TAR} ${env.SSH_USER}@${REMOTE_IP}:${DEPLOY_PATH}/${IMAGE_TAR}"
            }
          }
        }

        

        stage('Cleanup Docker & Local Artifacts') {
          steps {
            script {
              try {

                sh "docker rmi -f ${IMAGE_NAME}"


                sh "docker container prune -f"
                sh "docker image prune -f"
                sh "docker builder prune -f"

                sh "rm -f ${IMAGE_TAR}"
              } catch (e) {
                echo "Cleanup failed or nothing to clean, ignoring: ${e}"
              }
            }
          }
        }        

        stage('Execute Deployment') {
          steps {
            sshagent(credentials: ["${env.SSH_CRED_ID}"]) {
            withCredentials([
              usernamePassword(credentialsId: 'eureka-credentials', usernameVariable: 'EUREKA_USERNAME', passwordVariable: 'EUREKA_PASSWORD')
            ]) {
            sh """
    ssh -T -o StrictHostKeyChecking=no ${SSH_USER}@${REMOTE_IP} << EOF
        # Load the new image
        docker load -i ${DEPLOY_PATH}/${IMAGE_TAR}
        
        # Stop and remove existing container if it exists
        docker rm -f ${APP_NAME} || true
        
        # Run the new container
        docker run -d \\
            --name ${APP_NAME} \\
            --memory 768m --memory-swap 768m --restart unless-stopped \\
            --network royawl-bridge \\
            -p 8761:8761 \\
            -v /home/ubuntu/documents/royawl:/app/data/royawl \\
            -v /home/ubuntu/config/royawl-eureka-server/log4j2.xml:/config/log4j2.xml \\
            -e LOG4J2_CONFIG=/config/log4j2.xml \\
            -e SPRING_PROFILES_ACTIVE=prod \\
            -e SPRING_OUTPUT_ANSI_ENABLED=NEVER \\
            -e SERVER_PORT=8761 \\
            -e EUREKA_USERNAME="${EUREKA_USERNAME}" \\
            -e EUREKA_PASSWORD="${EUREKA_PASSWORD}" \\
            ${IMAGE_NAME}
            
        # Cleanup the tar file to save space
        rm ${DEPLOY_PATH}/${IMAGE_TAR}
EOF
"""
            }
            }
          }
        }
        stage('Health Check') {

          steps {
            script {
              def HEALTH_URL = "https://api.royawl.com/api/system/healthcheck/eureka-server"
              retry(10) {
                sleep 15
                def response = sh(script: "curl -s -k ${HEALTH_URL} || echo 'failed'", returnStdout: true).trim()
                if (!response.contains('"success" : true')) {
                  error "App not healthy yet. Check logs on server."
                }
              }
            }
          }
        }
      }
    }
  }

  post {
    failure { echo "Deployment failed!" }
    success { echo "Deployment to Production successful." }
  }
}
