pipeline {
    agent any

    environment {
        // Variables pour Nexus
        NEXUS_URL = 'http://localhost:8081'
        NEXUS_REPO = 'hello'
        ARTIFACT_ID = 'hello-world'
        VERSION = '0.0.1'
        GROUP_ID = 'com.example'
        PACKAGING = 'jar'
        CREDENTIALS_ID = 'nexus-cred'
        
        // Docker image
        DOCKER_IMAGE_NAME = 'my-docker-image'
        DOCKER_IMAGE_TAG = 'latest'
        NEXUS_DOCKER_REPO = 'docker_image'
        NEXUS_DOCKER_REGISTRY = 'localhost:5000'
        
    }
    
    stages {
        
        stage('Checkout') {
            steps {
            checkout scm
            }
        }
        
        
        stage('Build') {
            steps {
                echo 'Build du projet Java...'
                bat 'mvn clean package'
                bat 'dir target'
            }
        }
        
        

        stage('Deploy to Nexus') {
            steps {
                echo 'Déploiement du .jar sur Nexus...'
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: 'localhost:8081',
                    groupId: "${GROUP_ID}",
                    version: "${VERSION}-SNAPSHOT",
                    repository: "${NEXUS_REPO}",
                    credentialsId: "${CREDENTIALS_ID}",
                    artifacts: [[
                        artifactId: "${ARTIFACT_ID}",
                        classifier: '',
                        file: "target/${ARTIFACT_ID}-${VERSION}-SNAPSHOT.jar",
                        type: 'jar'
                    ]]
                )
            }
        }

        stage('Pull Artifact from Nexus') {
            steps {
                echo 'Téléchargement du .jar depuis Nexus...'
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'NEXUS_REPO_USER', passwordVariable: 'NEXUS_REPO_PASS')]) {
                    bat """
                        curl -u %NEXUS_REPO_USER%:%NEXUS_REPO_PASS% -O %NEXUS_URL%/repository/%NEXUS_REPO%/%GROUP_ID.replace('.', '/')%/%ARTIFACT_ID%/%VERSION%/%ARTIFACT_ID%-%VERSION%.jar
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Construction de l\'image Docker...'
                bat "docker build -t %DOCKER_IMAGE_NAME%:%DOCKER_IMAGE_TAG% ."
            }
        }

        stage('Clean Trivy Cache') {
            steps {
                echo 'Nettoyage du cache Java de Trivy...'
                bat """
                    docker run --rm aquasec/trivy clean --java-db
                """
            }
        }

        stage('TRIVY IMAGE SCAN') {
            steps {
                echo 'Scan Trivy sur l\'image Docker...'
                bat """
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v %CD%:/root/.cache/ aquasec/trivy image --timeout 10m %DOCKER_IMAGE_NAME%:%DOCKER_IMAGE_TAG% > trivy-image.txt
                """
            }
        }

        stage('TRIVY FS SCAN') {
            steps {
                echo 'Scan Trivy sur le système de fichiers...'
                bat """
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v %CD%:/scan aquasec/trivy fs --timeout 10m /scan > trivy-fs.txt
                """
            }
        }

        stage('Push Docker Image to Docker Hub') { 
            steps {
                echo '🚀 Push de l\'image Docker vers Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-account', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    bat """
                        docker tag %DOCKER_IMAGE_NAME%:%DOCKER_IMAGE_TAG% %DOCKERHUB_USER%/%DOCKER_IMAGE_NAME%:%DOCKER_IMAGE_TAG%
                        docker login -u %DOCKERHUB_USER% -p %DOCKERHUB_PASS%
                        docker push %DOCKERHUB_USER%/%DOCKER_IMAGE_NAME%:%DOCKER_IMAGE_TAG%
                    """
                }
            }
        }

        stage('Upload K8s Manifests to Nexus') {
            steps {
                echo '📦 Upload des manifests Kubernetes vers Nexus...'
                withCredentials([usernamePassword(credentialsId: "${CREDENTIALS_ID}", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    bat """
                        curl -u %NEXUS_USER%:%NEXUS_PASS% --upload-file "%CD%\\k8s\\svc.yaml" %NEXUS_URL%/repository/%NEXUS_REPO%/k8s/svc.yaml
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Déploiement complet réussi : artefact Maven + image Docker + scans Trivy !'
        }
        failure {
            echo '❌ Le pipeline a échoué.'
        }
    }
}

