node('docker') {

  stage 'Checkout'

    checkout scm

  stage 'Acquire util'

    sh 'mkdir -p tmp'
    dir('tmp'){
      git([ url: "https://github.internet2.edu/docker/util.git",
          credentialsId: "jenkins-github-access-token" ])
      sh 'ls'
      sh 'rm -rf ../bin/windows/'
      sh 'mv bin/* ../bin/.'
    }
  stage 'Setting build context'
  
    def maintainer = maintainer()
    def previous_maintainer = previous_maintainer()
    def imagename = imagename()
    def tag
    
    // Tag images created on master branch with 'latest'
    if(env.BRANCH_NAME == "master"){
      tag = "latest"
    }else{
      tag = env.BRANCH_NAME
    }
        
    if(!imagename){
      echo "You must define an imagename in common.bash"
      currentBuild.result = 'FAILURE'
     }
     if(maintainer){
      echo "Building ${imagename}:${tag} for ${maintainer}"
     }

  stage 'Build'
    try{
      sh 'bin/rebuild.sh &> debug'
    } catch(error) {
      def error_details = readFile('./debug');
      def message = "BUILD ERROR: There was a problem building the shibboleth-sp image. \n\n ${error_details}"
      sh "rm -f ./debug"
      handleError(message)
    }
  stage 'Start container'

    sh 'bin/ci-run.sh'

  stage 'Tests'

    try{
      sh 'bin/test.sh &> debug'
    } catch(error) {
      def error_details = readFile('./debug');
      def message = "BUILD ERROR: There was a problem testing ${imagename}:${tag}. \n\n ${error_details}"
      sh "rm -f ./debug"
      handleError(message)
    }

  stage 'Scan'

    try {
          // Install trivy and HTML template
          sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.31.1'
          sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > html.tpl'

          // Scan container for all vulnerability levels
          sh 'mkdir -p reports'
          sh "trivy image --ignore-unfixed --vuln-type os,library --severity CRITICAL,HIGH --no-progress --security-checks vuln --format template --template '@html.tpl' -o reports/container-scan.html ${maintainer}/${imagename}:latest"
          publishHTML target : [
              allowMissing: true,
              alwaysLinkToLastBuild: true,
              keepAll: true,
              reportDir: 'reports',
              reportFiles: 'container-scan.html',
              reportName: 'Security Scan',
              reportTitles: 'Security Scan'
          ]

          // Scan again and fail on CRITICAL vulns
          sh "trivy image --ignore-unfixed --vuln-type os,library --exit-code 1 --severity CRITICAL ${maintainer}/${imagename}:latest"
    } catch(error) {
      def error_details = readFile('./debug');
      def message = "BUILD ERROR: There was a problem scanning ${imagename}:${tag}. \n\n ${error_details}"
      sh "rm -f ./debug"
      handleError(message)
    }
    
  stage 'Stop container'

    sh 'bin/ci-stop.sh'

  stage 'Push'
    docker.withRegistry('https://registry.hub.docker.com/',   "dockerhub-$previous_maintainer") {
          def baseImg = docker.build("$maintainer/$imagename", "--no-cache .")
          baseImg.push("$tag")
    }

    docker.withRegistry('https://registry.hub.docker.com/',   "dockerhub-$previous_maintainer") {
          def altImg = docker.build("$previous_maintainer/$imagename", "--no-cache .")
          altImg.push("$tag")
    }

    
  stage 'Notify'
  
    slackSend color: 'good', message: "$maintainer/$imagename:$tag pushed to DockerHub"
}

def maintainer() {
  def matcher = readFile('common.bash') =~ 'maintainer="(.+)"'
  matcher ? matcher[0][1] : 'tier'
}

def previous_maintainer() {
  def matcher = readFile('common.bash') =~ 'previous_maintainer="(.+)"'
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
  sh 'exit 1'
}
