# tfstateファイルの保存先をs3バケットに変更
terraform {
  backend "s3" {
    bucket = "tf-ecs-fargate"
    key    = "terraform/ecs-fargate"
    region = "ap-northeast-1"
  }
}