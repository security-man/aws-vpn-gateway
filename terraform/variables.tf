# variables for execution
variable "region" {}
variable "shared_config_files" {}
variable "shared_credentials_files" {}
variable "profile" {}
variable "ENVIRONMENT" {
  type = string
}
variable "PROJECT" {
  type = string
}
variable "cidr_block" {}