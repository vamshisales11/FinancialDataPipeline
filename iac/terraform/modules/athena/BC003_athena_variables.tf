variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "gold_bucket" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
