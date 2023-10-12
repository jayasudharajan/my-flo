# FloCloud - Infrastructure as a Code Documentation


## Technology stack

* Yq (Version 2.4.0)
* Jq (Version jq-1.6)
* Terraform (Version 0.11.14)
* Kops (Version 1.12.1)
* Kubernetes (Version 1.12)
* gotpl
* helm

## Overview
These `as a code` implementation consist of several parts thats at the below .

* <h4>Kubernetes Cluster </h4>

This cluster running with 7 (4 worker, 3 master) instance currently. This kubernetes instances are running on ubuntu based kope.io AMI's . These nodes are running as m4.large type of instances . 

* <h4>Secret Management at Kubernetes </h4>
Currently we are using kubernetes secrets for managing application and secrets of other component ( like instana ). 

If you want to access these values via kubectl client `kubectl get secret yaml $SECRET_NAME -o yaml`  after execute this command you will receive base63 encoded style of secret you can raw style of secret via `--decode` flag of `base64` command . 


## Terraform State

Each state of terraform modules or directly DSL implementation storing at remote S3 Bucket with own specified tfstate file remotely . If you want check, please take a look `backend.tf` on terraform related directories .

For example :

    cd terraform/kubernetes
    (
        echo "terraform {"
        echo "  backend \"s3\" {"
        echo "    region = \"${AWS_REGION}\""
        echo "    bucket = \"${TERRAFORM_BUCKET}\""
        echo "    key    = \"${TERRAFORM_BUCKET_KEY_PREFIX}/kubernetes.tfstate\""
        echo "    profile = \"${PROFILE}\""
        echo "  }"
        echo "}"
    ) > backend.tf



### SSH Keys

This implementation create private and public key for ssh connection after all those thing this created ssh key pair provide ssh access to the instances at LaunchConfiguration as you can see .

If you re-run this function it will create a new key-pair and old one will disappear so that you must apply the rolling update for whole cluster and that will create down-time .

For check the flow of these process check the `create_ssh_key` function .


### First Part

* VPC : Containing subnets, route table and rules, Internet Gateway , Nat Gateway  , EIP for network requirements itself .
* Route53 : This route53 modules create hosted zone `k8s.flocloud.co`
* S3 : Bucket that storing all states and credentials of kops based kubernetes cluster . 
* ACM : That certificate using for hosted zone trafic more securely expose traffic . 

### Second Part

This part is generating terraform implementation of whole cluster, creating all kubernetes credentials, certificates for instance groups communication between each other .

`kops` is using template definition as a yaml that related with `deployment/values.yaml` file . These all templates at the `templates` directory these templates just a template engine definition for `kops template box ` usage (take a look at line:236) .

These template definition containing metadata of instance group, in this cluster implementation we there type of instances :
* master : master instance group
* node : worker instance group
* gitlab-runner : it has a same position with `node group`  but at the application we just running runner and slave pods gitlabCI pipeline.
* gitlab-runner-firmware : similar to the previous group, but the node attributes are specific to the instance class needed for firmware builds.

If you check the `core` directory it has several nested directories , `kubernetes` is just one of them . This directory is only containing generated terraform implementation of `kops` .

After generated template files terraform and kops generate these code blocks and run of them all together . 

Generator commands (take a look at line: 288)
`    kops update cluster --name ${KOPS_CLUSTER_NAME} \
                        --target terraform \
                        --out terraform/kubernetes`
                        
### VPC Peering

At the current resources that living at different VPC's so that we need to create link between each other so that we are running vpc-peering modules at `terraform/vpc-peering` . These vpc is `kubernetes` and `dev` vpc resources.

Kloia VPC Peering Module : github.com/kloia/terraform-modules.git/?ref=v0.0.2

### Route53 Private HostedZone Assocations 

At the current state kafka instances running at the ec2 instance but dns resolving handling from private route53 hosted zone but hosted zone did not contain the kubernetes vpc . We have implemented at `#route53_association` function you can check `as a code ` implementation `terraform/route53-association` directory

## Access Kubernetes Instance

If you want to access via `kubectl` command you must check the IP restriction at security group of `API-LOAD-BALANCER` .

By additional if you want to access kubernetes instances via ssh you can receive the `ssh` private key from `flocloud-terraform-state` store specified you AWS Account ID . 


## UPGRADE PATH

### Kubernetes Version
Currently your kubernetes version is running on version `1.12` if you want to upgrade your current version of kubernetes on cluster, replace version at the `cluster.yaml` `nodes.yaml` and `master.yaml` tag of `kubernetesVersion` .


     spec:
       kubernetesVersion: "1.12.0" => "1.13.4"


After all those thing you can uncomment `kops upgrade cluster --yes` command after all those things you can re-run create_k8s.sh script and and rolling-update the all cluster .

### Kops Version

If you want manage the kubernetes cluster with different version of kops, after updated the cluster you must re-run create_k8s.sh script .This scripts will update all state whole of stack end of kops_create_cluster function it will update the cluster terraform output and re-run all of them . 


* By the way you can validate the state of cluster `kops validate cluster ` command and end of the script you can check status `kops rolling update cluster ` if output contain `NeedsUpdate` at the instance group you can add `--yes` flag to it it will upgrade all kops version generally of cluster but it will terminate and recreate instances with new configurations . 
