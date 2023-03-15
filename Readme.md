# Getting started

**Warning: Do not use this setup in a production environment unless you reviewed all security contexts. This setup was developed for presentation purposes** 

This repository contains all necessary sources for deploying a [kubernetes dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) to a kubernetes cluster using [Terraform](https://www.terraform.io/). 

If you want to deploy it on your Kubernetes instance, you have to adjust the kubernetes provider setting in `providers.tf`: 
````json
provider "kubernetes" {
  # adjust the config settings based on your k8s setup
  config_path    = <YOUR_CONFIG_PATH>
  config_context = <YOUR_CONFIG_CONTEXT>
}
````

Initialize and download the terraform providers: 
````sh
$terraform init

Initializing the backend...

Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "3.0.1"...
- Finding hashicorp/kubernetes versions matching "2.18.1"...
- Installing kreuzwerker/docker v3.0.1...
- Installed kreuzwerker/docker v3.0.1 (self-signed, key ID BD080C4571C6104C)
- Installing hashicorp/kubernetes v2.18.1...
- Installed hashicorp/kubernetes v2.18.1 (signed by HashiCorp)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```` 

Run a plan command to review the configuration: 
````sh
$terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
...
````

After reviewing the configuration, you can apply the setup: 
````sh
$terraform apply
...
Plan: 17 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + admin-token = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
  
  ...

  Apply complete! Resources: 17 added, 0 changed, 0 destroyed.
````

After the successful apply an output with the `admin-token` is displayed. this is for authenticating on the Web UI of the dashboard. Copy the token for later use 

````sh
...

Outputs:

admin-token = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImUweTk5bzRlb2ZWLXYZ
````

The resources are now set up accordingly. To expose the dashboard on localhost, open a terminal and run the proxy command: 
````sh
$kubectl proxy
Starting to serve on 127.0.0.1:8001
````

The dashboard should now be accessible via:

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

Authenticate with the copied token from the previous script: 
![Dashboard](/figures/k8s_dashboard_auth.png)

After successful authentication, you should be able to see the newly created namespace `kubernetes-dashboard`:
![Dashboard](/figures/k8s_dashboard.png)


