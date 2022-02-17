variable "shared" {
  type = list(object({
    name        = string
    destination = string
    id          = string
    subnets     = list(string)
    route_table = string
  }))
}

variable "members" {
  type = list(object({
    name        = string
    cidr        = string
    id          = string
    subnets     = list(string)
    route_table = string
  }))
}

variable "routes" {
  type = list(object({
    destination = string
    route_table = string
  }))
}