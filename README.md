# AWS LandingZone in Terraform

This solution helps you quickly deploy a secure, resilient, scalable, and fully automated cloud foundation that accelerates your readiness for your cloud compliance program. 

A landing zone is a cloud environment that offers a recommended starting point, including default accounts, account structure, network and security layouts, and so forth. From a landing zone, you can deploy workloads that utilize your solutions and applications.

It exists as an alternative to the AWS Landing Zone accelerator project and is designed to be executed within your existing CI/CD workflows, whether that's GitLab, GitHub, Bitbucket or something else.

## Scope of the Landing Zone Solution
The following details the effect remit of the Landing Zone solution:

* Configuration of Account and Organizational Units
* Provisioning of new AWS Accounts
* Management of the Organizational service control policies (TODO)
* Configuration of the Tagging Policies (TODO)
* Management of AWS Security Services AWS Config, SecurityHub and GuardDuty (TODO)
* Configuration and delivery of Organizational level IAM Policies, Identity Permission Sets, RoleSets and Usersets. (TODO)

## Initial Configuration

This solution requires a small amount of initial configuration in order to facilitate future automatic deployments.

You will need to create an AWS Organization, and (optionally) create resources to manage the Terraform state and OIDC provider.

The steps are outlined below:

* Login to a new, clean root AWS account, navigate to IAM Identity Centre - click the Enable button. Choose Enable with AWS Organizations when it gives you the option.
* Deploy a new CloudFormation stack using the template defined in ./oidc/github.yml, setting the input variables as appropriate. 
    * This stack creates an OIDC provider which allows GitHub actions to retrieve temporary credentials, as well as an S3 bucket and DynamoDB table to store the Terraform state remotely.
* In GitHub, navigate to the repository, click Settings, Secrets and Variables, Actions and add two new variables.
    * AWS_REGION is the "home region" you will use to manage your AWS Organization.
    * AWS_ACCOUNT_ID is the root AWS account that your AWS Organization hangs off.
* Once the CloudFormation stack is in the Created state, and the Variables have been set in Github, you can run the Deploy Terraform action defined for this repository and the organization will be created.