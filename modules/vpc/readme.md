
  # aws_eip.nat 
  # aws_internet_gateway.main 
  # aws_nat_gateway.main 
  # aws_route.private_nat_access 
  # aws_route.public_internet_access 
  # aws_route_table.private 
  # aws_route_table.public 
  # aws_route_table_association.private
  # aws_route_table_association.public
  # aws_subnet.private
  # aws_subnet.public
  # aws_vpc.main 

## Foundational Resources
aws_vpc (Virtual Private Cloud)

What it is: The main, isolated network environment in AWS.

Why it's here: It acts as the secure container for all your other network resources, like a private network in the cloud.

aws_internet_gateway (IGW)

What it is: A gateway that connects your VPC to the public internet.

Why it's here: It allows resources in your public subnets to be reached from the internet and to access the internet. It's the main door in and out of your VPC.

aws_subnet

What it is: A logical subdivision of your VPC's IP address range.

Why it's here: It's used to create two distinct zones:

Public Subnets: For resources that need to be publicly accessible, like web servers.

Private Subnets: For backend resources that should be kept secure and isolated from the internet, like databases.

## Resources for Private Subnet Connectivity
aws_eip (Elastic IP)

What it is: A static, public IP address that you reserve.

Why it's here: To give the NAT Gateway a fixed, unchanging public IP address.

aws_nat_gateway (NAT Gateway)

What it is: A "one-way door" to the internet for your private subnets.

Why it's here: It allows resources in the private subnets (like a database) to initiate connections out to the internet (e.g., to download software updates), but it prevents the internet from initiating connections in to those private resources, keeping them secure.

## Routing and Associations
aws_route_table

What it is: A set of rules (routes) that control where network traffic is directed.

Why it's here: Two are created to manage traffic differently:

One for public subnets, telling them to send internet-bound traffic to the Internet Gateway.

One for private subnets, telling them to send internet-bound traffic to the NAT Gateway.

aws_route

What it is: A single rule inside a route table.

Why it's here: The 0.0.0.0/0 route is the "default route." It tells the route table where to send any traffic that isn't destined for another location inside the VPC itself.

aws_route_table_association

What it is: The link that connects a subnet to a route table.

Why it's here: It's how you apply the routing rules to the subnets. Associating a subnet with the "public" route table is what makes it a public subnet.