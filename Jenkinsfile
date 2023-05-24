
pipeline {
    agent { node { label 'docker-multi-arch' } }
    environment { 
        maintainer = "t"
        imagename = 's'
        tag = 'l'
        DOCKERHUBPW=credentials('tieradmin-dockerhub-pw')

    }
    stages {
        stage('Setting build context') {
            steps {
                script {
                    maintainer = maintain()
                    imagename = imagename()
                    if(env.BRANCH_NAME == "master") {
                       tag = "latest"
                    } else {
                       tag = env.BRANCH_NAME
                    }
                    if(!imagename){
                        echo "You must define an imagename in common.bash"
                        currentBuild.result = 'FAILURE'
                     }
                    sh 'mkdir -p tmp && mkdir -p bin'
                    dir('tmp'){
                      git([ url: "https://github.internet2.edu/docker/util.git", credentialsId: "jenkins-github-access-token" ])
                      sh 'rm -rf ../bin/*'
                      sh 'mv ./bin/* ../bin/.'
                    }
                    // Build and test scripts expect that 'tag' is present in common.bash. This is necessary for both Jenkins and standalone testing.
                    // We don't care if there are more 'tag' assignments there. The latest one wins.
                    sh "echo >> common.bash ; echo \"tag=\\\"${tag}\\\"\" >> common.bash ; echo common.bash ; cat common.bash"
                }  
             }
        }    
        stage('Clean') {
            steps {
                script {
                   try{
                     sh 'bin/destroy.sh >> debug'
                   } catch(error) {
                     def error_details = readFile('./debug');
                     def message = "BUILD ERROR: There was a problem building the Base Image. \n\n ${error_details}"
                     sh "rm -f ./debug"
                     handleError(message)
                   }
                }
            }
        } 
        stage('Build') {
            steps {
                script {
                  try{
                        sh 'docker login -u tieradmin -p $DOCKERHUBPW'
                        // fails if already exists
                        // sh 'docker buildx create --use --name multiarch --append'
                        sh 'docker buildx inspect --bootstrap'
                        sh 'docker buildx ls'
                        sh "docker buildx build --platform linux/amd64 -t ${imagename}_${tag} --load ."
                        sh "docker buildx build --platform linux/arm64 -t ${imagename}_${tag}:arm64 --load ."
                  } catch(error) {
                     def error_details = readFile('./debug');
                      def message = "BUILD ERROR: There was a problem building ${maintainer}/${imagename}:${tag}. \n\n ${error_details}"
                     sh "rm -f ./debug"
                     handleError(message)
                  }
                }
            }
        }
        stage('Test') {
            steps {
                script {
                   try {
                     echo "Starting tests..."
                     sh 'bats tests'
                     // echo "Skipping tests for now"
                   } catch (error) {
                     def error_details = readFile('./debug')
                     def message = "BUILD ERROR: There was a problem testing ${maintainer}/${imagename}:${tag}. \n\n ${error_details}"
                     sh "rm -f ./debug"
                     handleError(message)
                   } 
                }    
             }
        }
        stage('Scan') {
            steps {
                script {
                   try {
                         echo "Starting security scan..."
                         // Install trivy and HTML template
                         sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.31.1'
                         sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > html.tpl'

                         // Scan container for all vulnerability levels
                         echo "Scanning for all vulnerabilities..."
                         sh 'mkdir -p reports'
                         sh "trivy image --ignore-unfixed --vuln-type os,library --severity CRITICAL,HIGH --no-progress --security-checks vuln --format template --template '@html.tpl' -o reports/container-scan.html ${imagename}_${tag}"
                         sh "trivy image --ignore-unfixed --vuln-type os,library --severity CRITICAL,HIGH --no-progress --security-checks vuln --format template --template '@html.tpl' -o reports/container-scan-arm.html ${imagename}_${tag}:arm64"
                         publishHTML target : [
                             allowMissing: true,
                             alwaysLinkToLastBuild: true,
                             keepAll: true,
                             reportDir: 'reports',
                             reportFiles: 'container-scan.html',
                             reportName: 'Security Scan',
                             reportTitles: 'Security Scan'
                          ]
                         publishHTML target : [
                             allowMissing: true,
                             alwaysLinkToLastBuild: true,
                             keepAll: true,
                             reportDir: 'reports',
                             reportFiles: 'container-scan-arm.html',
                             reportName: 'Security Scan (ARM)',
                             reportTitles: 'Security Scan (ARM)'
                          ]
                         // Scan again and fail on CRITICAL vulns
                         //below can be temporarily commented to prevent build from failing
                         echo "Scanning for CRITICAL vulnerabilities only (fatal)..."
                         sh "trivy image --ignore-unfixed --vuln-type os,library --exit-code 1 --severity CRITICAL ${imagename}_${tag}"
                         sh "trivy image --ignore-unfixed --vuln-type os,library --exit-code 1 --severity CRITICAL ${imagename}_${tag}:arm64"
                         //echo "Skipping scan for CRITICAL vulnerabilities (temporary)..."
                   } catch(error) {
                           def error_details = readFile('./debug');
                           def message = "BUILD ERROR: There was a problem scanning ${imagename}:${tag}. \n\n ${error_details}"
                           sh "rm -f ./debug"
                           handleError(message)
                   }
                }
            }
        }
        stage('Push') {
            steps {
                script {
                        sh 'docker login -u tieradmin -p $DOCKERHUBPW'
                        // fails if already exists
                        // sh 'docker buildx create --use --name multiarch --append'
                        sh 'docker buildx inspect --bootstrap'
                        sh 'docker buildx ls'
                        echo "Pushing image to dockerhub..."
                        sh "docker buildx build --push --platform linux/arm64,linux/amd64 -t ${maintainer}/${imagename}:${tag} ."
                 }
            }
        }
        stage('Cleanup') {
            steps {
                script {
                   try{
		     echo "Cleaning up artifacts from the build..."
                     sh 'tests/cleanup.sh'
                   } catch(error) {
                     def error_details = readFile('./debug');
                     def message = "BUILD ERROR: There was a problem with cleanup of the image. \n\n ${error_details}"
                     sh "rm -f ./debug"
                     handleError(message)
                   }
                }
            }
        }
        stage('Notify') {
            steps{
                echo "$maintainer"
                slackSend color: 'good', message: "$maintainer/$imagename:$tag pushed to DockerHub"
            }
        }
    }
    post { 
        always { 
            echo 'Done Building.'
        }
        failure {
            // slackSend color: 'good', message: "Build failed"
            handleError("BUILD ERROR: There was a problem building ${maintainer}/${imagename}:${tag}.")
        }
    }
}


def maintain() {
  def matcher = readFile('common.bash') =~ 'maintainer="(.+)"'
  matcher ? matcher[0][1] : 'tier'
}

def imagename() {
  def matcher = readFile('common.bash') =~ 'imagename="(.+)"'
  matcher ? matcher[0][1] : null
}

def handleError(String message){
  echo "${message}"
  currentBuild.setResult("FAILED")
  slackSend color: 'danger', message: "${message}"
  //step([$class: 'Mailer', notifyEveryUnstableBuild: true, recipients: 'pcaskey@internet2.edu', sendToIndividuals: true])
  sh 'exit 1'
}

