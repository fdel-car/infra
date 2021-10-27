# Infrastructure

To test the Terraform integrations I used [this workflow](https://github.com/hashicorp/setup-terraform), I removed the step where they apply the Terraform configuration since Terraform Cloud is already taking care of that.
But I feel that even using GitHub Actions just for pull requests is quite nice :)

If you try to clone this project you won't be able to run any terraform commands since it's setup to run remotely, you'll need access to this project: https://app.terraform.io/app/strapi/workspaces/infra.
I can give you access to it if you want, no problem. They have some nice features like state locking, setting environment variables using Vault, etc.
