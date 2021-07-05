# Manual Container Webhook

This script can be run with the required arguments to trigger a rolling deployment of your container in an Azure Web App For Containers instance.

It is designed to be run in your CI scripts where you are also running docker build/tag/push/etc.  This is for two reasons.  One, the script, for now, requires calling `docker push` in order to get data about the image (yes this is as dumb as it sounds).  Two, you give it passwords as CLI arguments.  There are better ways to do this but I'm lazy and if you run it in a good CI tool it will mask them.  Keep these in mind if you decide to run it elsewhere.

### Required Arguments
1. IMAGE_REPOSITORY - Repo name only, no registry name or tag.  For example: `myapp`, not `dockerhub.io/myapp:latest`
2. IMAGE_TAG - The tag you are using in Azure for your continuous deployment
3. REGISTRY_FQDN - Domain name for your registry.  For example: `myreg.azurecr.io`
4. HOOK_URL - This will be something like `https://[myapp].azurewebsites.net/docker/hook`
5. HOOK_USER - From your publishing profile or if using Terraform can be gotten from `azurerm_app_service.main.site_credential.0.username`
6. HOOK_PASSWORD - From your publish profile or if using Terraform can be gotten from `azurerm_app_service.main.site_credential.0.password`