variable "cidr" {
  type = string
}

variable "az1" {
  type = string
}

variable "az2" {
  type = string
}

variable "allow_inbound" {
  type = list(object({
    protocol = string
    from_port = number
    to_port = number
    source = string
  }))
  default = []
}