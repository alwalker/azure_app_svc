# Simple App Service Setup
This folder contains the terraform needed to create a simple environment to host your application(s) using Azure App Services.  By default it will provision the following:
- App Service Plan (Basic B1)
    - Frontend and backend "web apps"
    - A scheduled jobs function app
- Redis (Basic C0)
- Azure Database For PostgreSQL (General Purpose Gen5 2vcore with 100MB of storage)
- Storage Account with two containers
- A Log Analytics Workspace that all logs and metrics for these services will be forwarded too

## Folder Structure
The folders at the root contain all the environments (qa, stage, etc) as well as the modules needed to build them (database, function_app, etc).  

By default, there is only one environment `qa`.  Inside this folder is a `main.tf` file that contains all the configuration that uses the modules to build your environment.  There are also a `variables.tf` and `qa.auto.exampletfvars` that have variable definitions and default values. The variables file contains everything but secrets.  The example file should be renamed to `qa.auto.tfvars` (and this should be in your gitignore) and filled with the required secrets.  There is also an `outputs.tf` file that will print useful information when you run `terraform apply`.

## Naming Conventions
Most everything will have the following naming convention: `[resource abbreviation]-[app name]-[environment]`.  These values are controlled by the `base_name` and `env` variables located in the folder for your environment.

## Sizing
The default sizing for everything is basically the minimum it can be and still support all the features we need. This should cost roughly $225 a month.  Below are some things to note about these defaults but more details can be found on the pricing details page for each product. 

### App Service Plan
All of your containers will run on the same plan.  By default, it only has one core and a little under 2GB of memory.  This is enough for simple API and static frontend or a server side rendering application but not much else.  The plan can be scaled vertically (i.e. make the existing instance larger) as well as horizontally (i.e. add more instances) w/o interruption but must be done manually.  If you want autoscaling you have to upgrade to a `Standard` tier plan.  This can also be done w/o interruption.

### Database
By default, the database is in the General Purpose tier and has 2 vcores with 100GB of storage.  This tier was chosen because while you can get similar performance with less reliability in the Basic tier you can not upgrade out of the Basic tier.  If you choose to go that route note that you will have to backup and restore the existing Basic database into either a General Purpose or Memory Optimized tier database.  One other thing to note is that while you can go up and down in the number of vcores (and therefore memory) you can not scale storage back once provisioned.

### Redis
This is the cheapest option for Redis.  One node, 250MB of memory, no backups, no SLA.

### Storage Account and Log Analytics
Storage, as well as logs, are charged based on how much you store and how much you transfer.  The logs by default are kept for 30 days.

## Containers
Both the web app and function app modules are designed to be used with a SINGLE container hosted in a private registry.

They can be used with either multiple containers via docker compose or w/o a container entirely if you're using one of the supported runtimes.  To do this however you will need to modify the corresponding module.

To point the web/function app at the registry you will need to provide values for all of the `oci_reg_*` variables in both the `variables.tf` and `autovars` files.  

Continuous Deployment is enabled by default.  This will enable a webhook that you can POST to when you upload a new image for the tag being used by the app.  For an example of this check the samples provided in this repo.