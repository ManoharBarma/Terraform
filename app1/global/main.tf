# Define the two regions you are deploying to
variable "primary_region" {
  default = "us-west-2"
}
variable "secondary_region" {
  default = "us-central-1"
}

# --- Data sources to get information from your regional deployments ---
# This fetches the state file from your primary region's deployment
data "terraform_remote_state" "primary" {
  backend = "s3"
  config = {
    bucket = "my-enterprise-terraform-state-bucket" # Change this
    key    = "us-west-2/terraform.tfstate"
    region = "us-east-1"
  }
}

# This fetches the state file from your secondary region's deployment
data "terraform_remote_state" "secondary" {
  backend = "s3"
  config = {
    bucket = "my-enterprise-terraform-state-bucket" # Change this
    key    = "us-central-1/terraform.tfstate"
    region = "us-east-1"
  }
}

# --- Route 53 Resources for Failover ---
resource "aws_route53_zone" "primary" {
  name = "my-cool-app.com" # Change to your domain
}

resource "aws_route53_health_check" "primary_alb_health_check" {
  # This checks the health of the primary ALB in us-west-2
  fqdn = data.terraform_remote_state.primary.outputs.application_endpoint
  port = 80
  type = "HTTP"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_record" "primary_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "app.my-cool-app.com" # The subdomain for your app
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary-us-west-2"
  health_check_id = aws_route53_health_check.primary_alb_health_check.id

  alias {
    name                   = data.terraform_remote_state.primary.outputs.application_endpoint
    zone_id                = data.terraform_remote_state.primary.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "app.my-cool-app.com"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary-us-central-1"
  # Note: No health check on the secondary. It becomes active only when the primary fails.

  alias {
    name                   = data.terraform_remote_state.secondary.outputs.application_endpoint
    zone_id                = data.terraform_remote_state.secondary.outputs.alb_zone_id
    evaluate_target_health = false
  }
}