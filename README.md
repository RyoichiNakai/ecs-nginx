# ecs-template

## 変更箇所

- `variables.tf`の以下の部分を変更

```tf
variable "profile" {
  type        = string
  default     = "dmm-trial" # この部分
  description = "TODO:設定したIAMユーザのプロファイルに変更"
}
```

- `backend.tf`にて、terraform の state ファイルの保存先の変更

```tf
terraform {
  backend "s3" {
    bucket = "tf-ecs-fargate"
    key    = "terraform/ecs-fargate"
    region = "ap-northeast-1"
  }
}
```
