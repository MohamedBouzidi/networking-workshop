variable "domain" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "tgw" {
  type = object({
    id          = string
    route_table = string
  })
  default = null
}

variable "az1" {
  type = string
}

variable "az2" {
  type = string
}