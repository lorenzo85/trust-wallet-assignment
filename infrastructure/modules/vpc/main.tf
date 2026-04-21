# ──────────────────────────────────────────────────────────────────────────────
# VPC - multi-AZ with one NAT Gateway per AZ for high availability.
# ──────────────────────────────────────────────────────────────────────────────

locals {
  prefix = "${var.project}-${var.environment}"

  # Map of az -> { public_cidr, private_cidr } - drives all for_each blocks.
  # Compute the private and public CIDRs for each Availability Zone config.
  # This will be used below to create public and private subnets.
  az_config = {
    for i, az in var.azs : az => {
      public_cidr  = var.public_cidrs[i]
      private_cidr = var.private_cidrs[i]
    }
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.prefix}-vpc" }
}

# ── Subnets ───────────────────────────────────────────────────────────────────
# For each AZ we create a public and a private subnet.

resource "aws_subnet" "public" {
  for_each = local.az_config

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.public_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = { Name = "${local.prefix}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = local.az_config

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.private_cidr
  availability_zone = each.key

  tags = { Name = "${local.prefix}-private-${each.key}" }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
# An Internet Gateway is needed so that services deployed within the VPC can access the internet.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${local.prefix}-igw" }
}

# ── NAT Gateways (one per AZ) ─────────────────────────────────────────────────
# NAT Gateway is needed by services running in the private subnet to connect to the internet.
# NAT Gateway connects to the Internet Gateway and performs network address translation from private IPs.
resource "aws_eip" "nat" {
  for_each = local.az_config

  domain = "vpc"

  tags = { Name = "${local.prefix}-nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "this" {
  for_each = local.az_config

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = { Name = "${local.prefix}-nat-${each.key}" }

  depends_on = [aws_internet_gateway.this]
}

# ── Security Group: App (ECS tasks) ───────────────────────────────────────────
resource "aws_security_group" "app" {
  name        = "${local.prefix}-app-sg"
  description = "ECS tasks - egress to NAT and VPC endpoints"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "All egress (via NAT or VPC endpoints)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-app-sg" }
}

# ── Route Tables ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${local.prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each = local.az_config

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = local.az_config

  vpc_id = aws_vpc.this.id

  tags = { Name = "${local.prefix}-private-rt-${each.key}" }
}

resource "aws_route" "private_nat" {
  for_each = local.az_config

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = local.az_config

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
