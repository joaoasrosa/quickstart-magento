# quickstart-magento
## Magento on the AWS Cloud

This Quick Start automatically deploys Magento Open Source (formerly Community Edition) on the AWS Cloud.

Magento is an open-source content management system for e-commerce websites. This automated deployment builds a cluster that runs Magento along with optional sample data, which lets you experiment with custom themes and view the web store.

The deployment supports the use of either MySQL on Amazon RDS or Amazon Aurora (the default) for database operations, Amazon EFS for shared storage between EC2 instances, and an Amazon ElastiCache cluster with the Redis cache engine to improve application load times. Note that Amazon EFS and Amazon Aurora are not currently supported in all AWS Regions, so [make sure both services are available in the desired region](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/) before launching a stack.

You can use the AWS CloudFormation templates included with the Quick Start to deploy a fully configured Magento infrastructure in your AWS account. The Quick Start automates the following:
  * Deploying Magento Open Source into a new VPC
  * Deploying Magento Open Source into an existing VPC

You can also use the AWS CloudFormation templates as a starting point for your own implementation.

![Quick Start Magento Design Architecture](http://docs.aws.amazon.com/quickstart/latest/magento/images/magento-with-aurora-architecture.png)

For architectural details, best practices, step-by-step instructions, and customization options, see the [deployment guide](http://docs.aws.amazon.com/quickstart/latest/magento/welcome.html).
