# LogScale Cluster Deployment in Azure AKS

## Overview :

This document is a guide to provision a self-hosted LogScale cluster on Azure Cloud using Azure AKS kubernetes, with Azure object store for event repositories.

The sequence of steps and associated tasks required to provision LogScale are split into sections for planning, deployment, and validation. Sections should be processed in top-down order to ensure that prerequisites are met as provisioning steps are executed.

Notes:

- This cluster deployment utilizes an independent Kafka service.
- This document assumes at least intermediate level knowledge of Azure Cloud.

## Architectural Diagrams:

**Deployment Overview:**

![dep_overview](/docs/asset/dep-overview.png) 

**Functional Overview:**

![fun-overview](/docs/asset/fun-overview.png) 

## Prerequisites :

- Falcon LogScale License Key
- LogScale Instance sizing guidelines:
  - [Instance Sizing](https://library.humio.com/falcon-logscale-self-hosted/installation-provisioning-sizing.html)
  - [Recommended Instance Sizing](https://library.humio.com/falcon-logscale-self-hosted/installation-prep-rec.html)
- Azure Portal account with an active subscription
- Azure Storage account
  - [Create a storage account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal)
- Azure Blob Container (i.e. storage bucket)
  - [Create a blob container](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-portal#create-a-container)
- Good understanding of [Azure Resource groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- Good understanding Kubernetes

## Deployment:

**1. Create an AKS cluster using any of the following methods:**

  - [Azure CLI](https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli)
  - [Azure Portal](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal?tabs=azure-cli#create-an-aks-cluster)
  - [Terraform](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-terraform?tabs=azure-cli#implement-the-terraform-code)

Validate the cluster is up and running by checking kubernetes service status:

- kubectl get svc

**2. Deploy Kafka/ZooKeeper to the AKS cluster using the** [strimzi-kafka-operator](https://github.com/strimzi/strimzi-kafka-operator)
  - Note: Default partition count is 24. Refer to [LogScale Digest Rules] (https://library.humio.com/falcon-logscale-self-hosted/cluster-management-digest-rules.html)
  - Deploy the strimzi-kafka-operator (kafka/k8s orchestration facility - [strimzi key features](https://strimzi.io/docs/operators/latest/overview.html#key-features-product_str))
    - Execute following commands in K8s environment
      - helm repo add strimzi [https://strimzi.io/charts/](https://strimzi.io/charts/)
      - helm repo update
      - helm install strimzi-kafka strimzi/strimzi-kafka-operator

  - Provision the Kafka+zookeeper cluster
    - Configure Kafka/zookeeper parameters (see sample kafka-zookeeper.yaml)
      - replicas
      - offsets.topic.replication.factor
      - transaction.state.log.replication.factor
      - transaction.state.log.min.isr
      - default.replication.factor
      - min.insync.replicas
      - Inter.broker.protocol.version
      - storage.size
    - Apply Kafka yaml
  - Validate installation by checking pods and services

- kubectl get pods
- kubectl get svc

**3. Deploy S3Proxy**

  - LogScale supports S3 compatible storage using S3Proxy service. Azure Blob Storage is one of them. For more information on S3Proxy, see [here](https://github.com/gaul/s3proxy).
  - Provision S3Proxy node(s)
    - Configure parameters as required (see sample s3proxy.yaml)
      | Name | Value |
      | :-- | :-- |
      | S3PROXY\_AUTHORIZATION | `none` |
      | JCLOUDS\_PROVIDER | `azureblob` |
      | JCLOUDS\_ENDPOINT | \<Azure storage a/c endpoint\> |
      | JCLOUDS\_IDENTITY | \<Azure storage a/c name\> |
      | JCLOUDS\_CREDENTIAL | \<Azure storage a/c access key\> |
      | JCLOUDS\_AZYREBLOB\_AUTH | `azureKey` |
      | LOG\_LEVEL | `debug` |
    - Apply S3Proxy & S3Proxy service (see sample s3proxy-service.yaml)
  - Verify that s3proxy pod and service are running.

**4. Deploy LogScale**
  - Note: This deployment uses NODE\_ROLES="all". For details, refer to [](https://library.humio.com/falcon-logscale-self-hosted/envar-node-roles.html) 
  - Deploy LogScale Operator (see setup\_logscale.sh)
    - Obtain the latest stable version from [LogScale Operator Releases](https://github.com/humio/humio-operator/releases).
    - Apply LogScale CRDs & Operator
  - Configure LogScale
    - Create a license key secret
      - kubectl create secret generic example-humiocluster-license --from-literal=data=\<LogScale License\>
    - Obtain the latest stable version from [LogScale Releases](https://library.humio.com/release-notes/release-notes-stable.html).
    - In HumioCluster yaml, set the parameters as required (see sample logscale-cluster.yaml)
      - Set the parameters under spec
        - targetReplicationFactor
        - storagePartitionsCount
        - digestPartitionsCount
      - Set the Env. variables under spec.environmentVariables which are required to enable the S3 compatible storage
        | Name | Value |
        | :-- | :-- |
        | USING\_EPHEMERAL\_DISKS | `true` |
        | NODE\_ROLES | `all | ingestonly | httponly`
        | S3\_STORAGE\_ENDPOINT\_BASE | \<s3proxy endpoint\> |
        | S3\_STORAGE\_ACCESSKEY | \<Azure Storage a/c accesskey\> |
        | S3\_STORAGE\_SECRETKEY | \<Azure Storage a/c accesskey\> |
        | LOCAL\_STORAGE\_PERCENTAGE | "80" |
        | S3\_STORAGE\_PATH\_STYLE\_ACCESS | `true` |
        | S3\_STORAGE\_IBM\_COMPAT | `true` |
        | BUCKET\_STORAGE\_IGNORE\_ETAG\_UPLOAD | `true` |
        | BUCKET\_STORAGE\_IGNORE\_ETAG\_AFTER\_UPLOAD | `false` |
        | BUCKET\_STORAGE\_SSE\_COMPATIBLE | `true` |
        | S3\_STORAGE\_ENCRYPTION\_KEY | `off` |
        | S3\_STORAGE\_BUCKET | "\<blob container\>" |
        | S3\_ARCHIVING\_PATH\_STYLE\_ACCESS | `true` |
        | S3\_EXPORT\_PATH\_STYLE\_ACCESS | `true` |
        | S3\_STORAGE\_PREFERRED\_COPY\_SOURCE | `true`

        More information on environment variables : [Falcon LogScale - Configuration Parameters](https://library.humio.com/falcon-logscale-self-hosted/envar.html)
      - Apply HumioCluster yaml
    - Status of each container can be checked by running following command:
      - kubectl get pods
      - kubectl describe pod \<humio-cluster-name\>

**5. Test and Verify**

- Check availability of pods and services
  - kubectl get pods
  - kubectl get svc
- Test connectivity and availability of LogScale cluster forwarding the port locally
  - kubectl port-forward svc/example-humiocluster 8888:8080

**6. Deploy Application gateway and enable AGIC**
- Deploy Application Gateway Ingress Controller Add-on to access LogScale App from the Internet
  - [Create and configure Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/quick-create-portal)
  - [Enable the ingress controller add-on for a new AKS cluster](https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new)



**Useful Reference Links:**
  - [LogScale K8s Reference Architecture](https://library.humio.com/falcon-logscale-self-hosted/installation-k8s-ref-arch.html)
  - [K8s core concept for AKS](https://learn.microsoft.com/en-us/azure/aks/concepts-clusters-workloads)

<p align="center"><img src="docs/asset/cs-logo-footer.png"><BR/><img width="150px" src="docs/asset/adversary-red-eyes.png"></P>
<h3><P align="center">WE STOP BREACHES</P></h3>
