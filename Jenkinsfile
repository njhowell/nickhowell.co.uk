node {
  deleteDir()

  stage('Checkout')
  {
    checkout scm
  }
  
  def buildEnv = docker.build 'nickhowellcouk-node'
  buildEnv.inside {
    stage('D/L dependencies')
    {
        sh 'bundle install --path /tmp/.gem/'
    }
    

    stage('Build')
    {
        sh 'bundle exec jekyll build'
        archive '_site/**'
        stash includes: '_site/**', name: 'built-site'        
    }    
  }
}

if (currentBuild.result == 'UNSTABLE') {
  echo 'Skipping deployment due to unstable build'
} else {

    stage('Deploy')
    {
        node() {
            deleteDir()
            unstash 'built-site'
            sshagent(['webdeploy']) {
                sh 'rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress ./_site/ webdeploy@web2.nickhowell.co.uk:/opt/nickhowell.co.uk/'
            }
        }
    }
  
}
