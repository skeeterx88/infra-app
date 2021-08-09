# Terraform - EKS - Helm
Pedro Veríssimo Dantas Neto (pedro@verissimo.net.br)

## Technologies Used in Challenge
1. terraform
    - Used to build and manage infrastructure like code
2. Amazon EKS (Elastic Kubernetes Service)
    - Cloud-based container management service that natively integrates with Kubernetes to deploy applications. 
3. helm
    - Package manager for Kubernetes that allows developers and operators to more easily package, configure, and deploy applications and services onto Kubernetes clusters.
4. Jenkins
    - An open source automation server which enables developers around the world to reliably build, test, and deploy their software.
## Accomplished integrations
1. AWS terraform provider
    - used to interact with the many resources supported by AWS like VPC, security groups and EC2.
2. Kubernetes terraform provider
    - Used to manage kubernetes resources, such as pods, services, policies, quotas and more.
3. helm terraform provider  
    - Used to deploy software packages in Kubernetes. Applying resources, replicas, autoscale and rollback strategies.

## For this challenge, you will need:
- An AWS account with the IAM permissions listed on the EKS module documentation,
- A configured AWS CLI
- AWS IAM Authenticator
- kubectl
- wget (required for the eks module)
- helm (required for deploy the applications)

## Configfure AWS CLI
```aws configure```

     AWS Access Key ID [None]: YOUR_AWS_ACCESS_KEY_ID
     AWS Secret Access Key [None]: YOUR_AWS_SECRET_ACCESS_KEY
     Default region name [None]: YOUR_AWS_REGION
     Default output format [None]: json

```git clone https://bitbucket.org/naturacode/devops/ && cd devops/```

## List of files and their descriptions
1. [providers.tf](providers.tf) defines the providers configuration. 
2. [versions.tf](versions.tf) sets the Terraform version to at least 0.14. It also sets versions for the providers used in this challenge. 
3. [variables.tf](variables.tf) defines the variables.
4. [vpc.tf](vpc.tf) provisions a VPC, subnets and availability zones using the AWS VPC Module. 
5. [security-groups.tf](security-groups.tf) provisions the security groups used by the EKS cluster.
6. [eks-cluster-nodes.tf](eks-cluster-nodes.tf) provisions all the resources (AutoScaling Groups, etc...) required to set up an EKS cluster using the AWS EKS Module.
7. [outputs.tf](outputs.tf) defines the output configuration.
8. [get_info.sh](get_info.sh) get jenkins installation information.

## Initialize Terraform workspace
```terraform init```
## Provision the EKS cluster
```terraform plan```

```terraform apply -auto-approve```
### Configure kubectl
```aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)```

### Get info of the nodes
```kubectl get nodes```

### Get info of the cluster
```kubectl cluster-info```

## Get the info Jenkins
### App-01 URL access test
```./get_info.sh```

## Managing Configurations for Different Environments
### multiple environments in terraform
For deploy it to multiple environments I would recommend using one Terraform project but for each environment use a separate Terraform variables file and a separate Terraform workspace.

Your project will then look something like this:
```
dev.tfvars
qa.tfvars
prd.tfvars
```
Each environment variable file will then be run with the corresponding Terraform workspace to track Terraform State separately for each environment.

### Infrastructure testing
Having infrastructure tests helps ensure that what you wanted Terraform to create is what was actually created in your AWS account.

### Jenkins
Jenkins facilitates continuous integration and continuous delivery in software projects by automating parts related to build, test, and deployment. 

You can integrate with git, create a pipeline and deploy in the configured environment.

### Configure Jenkins
Create a CI/CD pipeline with Kubernetes and Jenkins
![Jenkins-01](./images/jenkins-01.jpg)

Create a new Jenkins job and select the Pipeline type. The job settings should look as follows:
![Jenkins-02](./images/jenkins-02.jpg)
Repository URL: https://github.com/skeeterx88/app
![Jenkins-03](./images/jenkins-03.png)

#### Configure Jenkins Credentials For GitHub and Docker Hub
![Jenkins-04](./images/jenkins-04.png)
![Jenkins-05](./images/jenkins-05.png)

### Sample Jenkinsfile
```
#!groovy

pipeline {
    parameters {
    password (name: 'AWS_ACCESS_KEY_ID')
    password (name: 'AWS_SECRET_ACCESS_KEY')
  }
  environment {
    TF_WORKSPACE = 'dev' 
    TF_IN_AUTOMATION = 'true'
    AWS_ACCESS_KEY_ID = "${params.AWS_ACCESS_KEY_ID}"
    AWS_SECRET_ACCESS_KEY = "${params.AWS_SECRET_ACCESS_KEY}"
  }
  agent none
    stage('Docker Build') {
      agent any
      steps {
        sh 'docker build -t skeeterx/app:latest .'
      }
    }
    stage('Docker Push') {
      agent any
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
          sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
          sh 'docker push skeeterx/app:latest'
        }
      }
    }
    stage ('Deploy') {
      steps {
        script{
          aws eks --region $(region) update-kubeconfig --name $(cluster_name)
          helm install app chart/ --values chart/values.yaml -n app --create-namespace
        }
      }
    }    
  }
}
```

### Application repository
https://github.com/skeeterx88/app

### Testing application
```
# matéria 1
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"alice@example.com","comment":"first post!","content_id":1}'
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"alice@example.com","comment":"ok, now I am gonna say something more useful","content_id":1}'
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"bob@example.com","comment":"I agree","content_id":1}'

# matéria 2
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"bob@example.com","comment":"I guess this is a good thing","content_id":2}'
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"charlie@example.com","comment":"Indeed, dear Bob, I believe so as well","content_id":2}'
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"eve@example.com","comment":"Nah, you both are wrong","content_id":2}'

# listagem matéria 1
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/list/1

# listagem matéria 2
curl -sv $(kubectl get service -n app-01 -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}/api/comment/list/2
```
