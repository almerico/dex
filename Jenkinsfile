pipeline {
    agent {
        label "jenkins-go"
    }
    environment {
      ORG               = 'jenkins-x'
      APP_NAME          = 'dex'
      GIT_PROVIDER      = 'github.com'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/coreos/dex') {
            checkout scm
            container('go') {
              sh "make test release-binary"

              sh 'export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml'

              sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
            }
          }
          dir ('/home/jenkins/go/src/github.com/coreos/dex/charts/preview') {
            container('go') {
              sh "make preview"
              sh "jx preview --app $APP_NAME --dir ../.."

              // verify if the preview was properly deployed 
              sh 'jx step verify --pods=1 --after=120 --restarts=0'
            }
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          container('go') {
            dir ('/home/jenkins/go/src/github.com/coreos/dex') {
              checkout scm
            }
            dir ('/home/jenkins/go/src/github.com/coreos/dex/charts/dex') {
                // ensure we're not on a detached head
                sh "git checkout master"
                // until we switch to the new kubernetes / jenkins credential implementation use git credentials store
                sh "git config --global credential.helper store"

                sh "jx step git credentials"
            }
            dir ('/home/jenkins/go/src/github.com/coreos/dex') {
              // so we can retrieve the version in later steps
              sh "echo \$(jx-release-version) > VERSION"
            }
            dir ('/home/jenkins/go/src/github.com/coreos/dex/charts/dex') {
              sh "make tag"
            }
            dir ('/home/jenkins/go/src/github.com/coreos/dex') {
              container('go') {
                sh "make test release-binary"
                sh 'export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml'

                sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
              }
            }
          }
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/coreos/dex/charts/dex') {
            container('go') {
              sh 'jx step changelog --version v\$(cat ../../VERSION)'

              // release the helm chart
              sh 'jx step helm release'

              // promote through all 'Auto' promotion Environments
              sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'

              // verify if the preview was properly deployed 
              sh 'jx step verify --pods=1 --after=120 --restarts=0'
            }
          }
        }
      }
    }
    post {
        always {
            cleanWs()
        }
    }
  }
