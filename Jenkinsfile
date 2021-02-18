@Library('github.com/releaseworks/jenkinslib') _

pipeline {
  
  agent any
  
  environment {
    //registry = "127.0.0.1:8082/repository/krasko"
    registry = "83a043ccc469.ngrok.io/repository/krasko"
    nexusServer = "http://83a043ccc469.ngrok.io"
    registryCredential = "cred"
    dockerImageBackand = ''
    dockerImageFrontend = ''
    SONARQUBE_LOGN_PROJECT = credentials('sonarqube_login_project')
    NEXUS_LOGIN = credentials('nexus_login')
    NEXUS_PASSWORD = credentials('nexus_password')
  }
  parameters {
    choice (
      choices: ['deploy', 'destroy', 'test'],
      description: '',
      name: 'REQUESTED_ACTION'
    )
  }
  
  tools {
    terraform 'Terraform'
  }
  stages {

  stage('Clean workspace') {
    when {
      expression { params.REQUESTED_ACTION == 'deploy'}
    }
    steps {
      cleanWs()
    }
  }
    
  stage('Pull from github') {
    when {
      expression { params.REQUESTED_ACTION == 'deploy'}
    }
    steps {
      git([url: 'https://github.com/BohdanKrasko/to-do-app', branch: 'main', credentialsId: 'to-do-app-github'])
    }
  }
    
  stage('Deploy frontend image') {
      when {
        expression { params.REQUESTED_ACTION == 'deploy'}
      }
      steps {
        script {
          
          dir('app/client') {
            dockerImageFrontend = docker.build registry + ":frontend_" + "$BUILD_NUMBER"
          }
          
          docker.withRegistry( nexusServer, registryCredential ) {
            dockerImageFrontend.push()
          }
        }
      }
    }
    
    stage('Deploy backend image') {
      when {
        expression { params.REQUESTED_ACTION == 'deploy'}
      }
      steps {
        script {
          
          dir('app/go-server') {
            dockerImageBackand = docker.build registry + ":backend_" + "$BUILD_NUMBER"
          }
          
          docker.withRegistry( nexusServer, registryCredential ) {
            dockerImageBackand.push()
          }
        }
      }
    }
    //stage('Sonarqube') {
    //  environment {
    //    scannerHome = tool 'SonarQubeScanner'
    //  }
    //  steps {
    //    withSonarQubeEnv('sonarqube') {
    //        
    //        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=project -Dsonar.sources=. -Dsonar.host.url=http://sonarqube:9000/ -Dsonar.login=$SONARQUBE_LOGN_PROJECT"
    //         
    //    }
    //  }
    //}
    stage('Terrafom') {
      when {
        expression { params.REQUESTED_ACTION == 'deploy'}
      }
      steps {
        
        dir('terraform') {
          withAWS(credentials:'aws_cred', region:'eu-west-3') {
            sh 'terraform init'
            sh 'terraform plan'
            sh 'terraform apply -auto-approve'
         }
        }
      }
    }
    
    stage('Deploy todo app in EKS cluster') {
      when {
        expression { params.REQUESTED_ACTION == 'deploy'}
      }
      steps {
        dir('kubernetes') {
          withAWS(credentials:'aws_cred', region:'eu-west-3') {
           // withEnv(["KUBECONFIG=/var/jenkins_home/workspace/to-do-app_main/terraform/kubeconfig_my-cluster"]) {
              sh (
                label: 'Run app',
                script: """#!/usr/bin/env bash 
                aws eks --region eu-west-3 update-kubeconfig --name my-cluster
                helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                helm repo update
                helm install ingress-nginx ingress-nginx/ingress-nginx
                sleep 30
                kubectl create secret docker-registry regcred --docker-server=83a043ccc469.ngrok.io --docker-username=$NEXUS_LOGIN --docker-password=$NEXUS_PASSWORD
                kubectl apply -f app/mongo.yml
                sleep 20
                helm install go helm/to-do-backend --set imageName=""$registry":backend_"$BUILD_NUMBER""
                helm install react helm/react-to-do --set imageName=""$registry":frontend_"$BUILD_NUMBER""
                """
            )
          //}
        }
      }
    }
  }
  
    stage('Ansible add A record') {
      when {
        expression { params.REQUESTED_ACTION == 'deploy'}
      }
      steps {
        dir('ansible') {
          withAWS(credentials:'aws_cred', region:'eu-west-3') {
            sh 'ansible-playbook dns.yml'
          }
        }
      }
    }
    
    stage('Destroy app') {
      when {
        expression { params.REQUESTED_ACTION == 'destroy'}
      }
      steps {
        withAWS(credentials:'aws_cred', region:'eu-west-3') {
          //withEnv(["KUBECONFIG=/var/jenkins_home/workspace/to-do-app_main/terraform/kubeconfig_my-cluster"]) { 
            sh (
                label: 'Run app',
                script: """#!/usr/bin/env bash
                helm install react
                helm install go
                helm install ingress-nginx
                kubectl delete secret regcred
                kubectl delete -f kubernetes/app/mongo.yml
                """
            )
          //}
        }
      } 
    }
    
   stage('Destroy cluster') {
     when {
        expression { params.REQUESTED_ACTION == 'destroy'}
     }
     steps {
       dir('terraform') {
          withAWS(credentials:'aws_cred', region:'eu-west-3') {
            sh 'terraform destroy -auto-approve'
         }
       }
     } 
   }
//    stage('Add A record') {
//      steps {
//        script {
//        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'aws-key', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
//        AWS("--region=eu-west-3 s3  ls")
//      }
//      }
//      }
//      
//    }
  }
}
