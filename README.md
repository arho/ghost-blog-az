# ghost-blog-az
## Getting Azure Environment Ready
Initialize Azure Environment for Terraform Remote Backend Usage

This can be done using `env-init` available in this repository.

It creates a resource group and storage account for storing terraform states.

Setting Up Repo to Use GitHub Actions for executing Terraform files.

This can basically be done through running:
```bash
export MSYS_NO_PATHCONV=1 
az ad sp create-for-rbac --name <service_principal_name> --role Contributor --scopes /subscriptions/<subscription_id>
```
Replacing `<subscription_id>` with desired one

After that, the values returned from the command above can be used as secrets in Github Actions.

## Workflow
After each pull request to the main branch, a pipeline verifying the changes made to the terraform file will be run.

Once the changes have been merged, another pipeline will take care of terraforming the environment.


## Time Constraint Shortcuts

- MySQL Database Security is not Optimal and was manually configured to disable SSL and allow Public Azure Services Access
- AzAPI was not allowing me to change the ACA resource without recreating it completely, therefore the `url` environment variable was set manually to the aca external address.

#### To remedy the former issue a few methods were tested and can be implemented:
- Storage Account connected to Azure Container Managed Environment and Defining SQLite volume for containers. (Not Optimal)
- Connecting the Database and the Azure Container Managed Environment to the same vNet, this would require Private DNS access configuration as well. (Has Potential)
- Containerizing the Database and Deploying it on AKS as a StatefulSet and connecting it to the current workload which doesn't seem to make a lot of sense.
- Service Connectors, I tested them heavily but was not able to replicate what I could achieve through the Web Portal on azure-cli and through AzAPI on Terraform.

## Final Notes:
Most of the time spent for this assignment was troubleshooting the connection between Ghost and its Database, which was completely inconsistent on ACA. A lot of the applied steps had to be retraced, redefined and applied and tested again. The AzAPI Terraform Provider was really interesting to deal with as well, since everything had to be mapped one-on-one to REST API calls. Overall, the behavior on ACA is a little bit unpredictable, the logging system can be unreliable for around 10-15 mins after the deployment so troubleshooting would take a lot of time.