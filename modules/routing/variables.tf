variable "attachments" {
  type = list(object({
    name            = string
    destination     = string
    id              = string
    subnets         = list(string)
    route_table     = string
    shared_services = bool
  }))
}

variable "routes" {
  type = list(object({
    destination = string
    route_table = string
  }))
}