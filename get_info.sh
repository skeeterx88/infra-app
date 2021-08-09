#!/bin/bash
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) >/dev/null 2>&1

jsonpath_pass="{.data.jenkins-admin-password}"
jsonpath_user="{.data.jenkins-admin-user}"
jsonpath_token="{.data.token}"
secret=$(kubectl get secret -n cicd jenkins -o jsonpath=$jsonpath_pass)
user=$(kubectl get secret -n cicd jenkins -o jsonpath=$jsonpath_user)
senha_token=$(kubectl get secret -n cicd $(kubectl get secret -n cicd| grep jenkins-token | awk '{print $1}') -o jsonpath=$jsonpath_token)

URL=$(kubectl get service jenkins -n cicd -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
USUARIO=`echo $(echo $user | base64 --decode)`
SENHA=`echo $(echo $secret | base64 --decode)`
TOKEN=`echo $(echo $senha_token | base64 --decode)`

echo "URL: $URL"
echo "Usuário: $USUARIO"
echo "Senha: $SENHA"
echo "Token: $TOKEN"