# Service名
variable "service_name" {
  type    = string
  default = "ecs-fargate"
}

# AWS Profile設定
variable "shared_credentials_files" {
  type    = list
  default = ["~/.aws/credentials"]
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "profile" {
  type        = string
  default     = "dmm-trial"
  description = "TODO:設定したIAMユーザのプロファイルに変更"
}

# VPCの設定
variable "azs" {
  type    = list
  default = ["ap-northeast-1c", "ap-northeast-1d"]
}

# パブリックサブネットのレンジ。azsと同じ数にする必要あり
variable "private_subnets" {
  type    = list
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

# パブリックサブネット
variable "public_subnets" {
  type    = list
  default = ["10.0.128.0/24", "10.0.129.0/24"]
}

# NGWの名前
variable "ngws" {
  type    = list
  default = ["1c", "1d"]
}
