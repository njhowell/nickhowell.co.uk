node {
  deleteDir()

  stage('Checkout')
  {
    checkout scm
  }
  
  def buildEnv = docker.build 'nickhowellcouk-node'
  buildEnv.inside('-u root') {
    stage('D/L dependencies')
    {
        sh 'bundle install'
    }
    

    stage('Build')
    {
        sh 'bundle exec jekyll build'
        archive '_site/**'
        stash includes: '_site/**', name: 'built-site'
        deleteDir()
    }    
  }
}

if (currentBuild.result == 'UNSTABLE') {
  echo 'Skipping deployment due to unstable build'
} else {

    stage('Deploy')
    {
        node() {
            
            unstash 'built-site'
        }
    }
  
}
