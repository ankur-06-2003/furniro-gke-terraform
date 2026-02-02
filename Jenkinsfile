pipeline {
    agent any
    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account')
    }
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose action: apply to create resources, destroy to delete them')
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/ankur-06-2003/furniro-gke-terraform.git'
            }
        }
        stage('Terraform Init') {
            steps {
  
                sh 'terraform init'

            }
        }
        stage('Terraform Plan') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh 'terraform plan  -var-file=values.tfvars'

            }
        }
        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh 'terraform apply --auto-approve  -var-file=values.tfvars'
            }
        }
        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                sh 'terraform destroy --auto-approve'
                // if you have multiple directories, you can uncomment and use the below code
                // dir('gke-terraform') {
                //     sh 'terraform destroy --auto-approve'
                // }
            }
        }
    }
}