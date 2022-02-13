variable "subnets" {
  type = list(object({
    id   = string
    name = string
  }))
}

variable "env" {
  type = string
}