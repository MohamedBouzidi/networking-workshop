variable "domain" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "nameserver" {
  type = string
}

variable "connect_transit" {
  type = bool
}

variable "transit_gateway" {
  type = string
}

variable "target_route_table" {
  type = string
}

variable "associated_route_table" {
  type = string
}

variable "az1" {
  type = string
}

variable "az2" {
  type = string
}

variable "cloud_domain" {
  type = string
}

variable "reverse_cloud_domain" {
  type = string
}

variable "resolver_endpoint_ips" {
  type = list(string)
}