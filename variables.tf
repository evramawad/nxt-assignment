variable "VPC_CIDR" {
  default = "10.0.0.0/16"
}

variable "NXT_Pub_Sub1" {
  default = "10.0.5.0/24"
}

variable "NXT_Pub_Sub2" {
  default = "10.0.6.0/24"
}
variable "NXT_Pri_Sub1" {
  default = "10.0.7.0/24"
}

variable "NXT_Pri_Sub2" {
  default = "10.0.8.0/24"
}

variable "mapPublicIP" {
  default = true
}