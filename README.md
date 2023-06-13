# Terraform-Project
Create an EC2 instance, deploy it on a custom VPC on a custom subnet and assign it a public IP address, so that not only can we SSH to it and connect to it and make changes on it, we can also automatically set up a web server to run on it so that we can handle web traffic.

Following are the steps to perform the above task:-
  1. Create VPC
  2. Create Internet Gateway
  3. Crate Custom Route Table
  4. Create a Subnet
  5. Associate subnet with route Table
  6. Create Security Group to allow port 22,80,443
  7. Create a network interface with an ip in the subnet that was created in step 4
  8. Assign an elastic IP to the network interface created in step 7
  9. Create ubuntu server and install/enable apache2
