**Assessment No.1:** 


● Write a Dockerfile that will run the app with security best practices in mind ( use any Hello World web application you want )

Find Dockerfile

● To deploy your application to AWS EKS, you'll need Kubernetes YAML
files. Create the YAML files required for deploying.

Find deployment.yml file

● We need to deploy the created docker to AWS EKS, which tool you use,
and provide the script used.

**Tool**:kubectl  

**Command:** kubectl apply -f eployment.yaml

----------------------------------------------------------------------------------------------------------------------------------------------
**Assessment No.2**


Only Overview plane for a new project with these elements:


1. Design the web application: Sketch a high-level architecture diagram of a
web application that demonstrates your ability to create a secure and
scalable system. Include components like the front end, back end, databases,
storage, caching, and networking elements.


![nwt_assignment](https://github.com/evramawad/nxt-assignment/assets/49963669/fc79a44f-b053-49dc-95d0-bea0888efcd0)


2. Infrastructure as Code (IaC): Outline the infrastructure setup using Infrastructure as Code concepts, using tools like Terraform, AWS CloudFormation, or similar.

Find Terraform folder


3. Cost optimization: Briefly discuss your strategy for optimizing resource
usage and costs without compromising security and scalability.

To handle scalabilty & cost optimization I used autoscaling in EKS to scale up and down depends on traffic load, and also we can use spot instances with many instance types to use lowest cost of instances.

For security all EKS resources exists in private subnets and only http traffic allowed to access frontend web application using ELB, and all resources accessing internet using NAT Gateway.

