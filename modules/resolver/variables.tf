variable "domain" {
    type = string
}

variable "nameserver" {
    type = string
}

variable "target_vpc" {
    type = object({
        id = string
        cidr = string
        subnets = list(string)
    })
}

variable "allowed_vpcs" {
    type = list(object({
        id = string
        cidr = string
        name = string
    }))
}