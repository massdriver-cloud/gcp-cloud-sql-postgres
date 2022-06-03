
module "apis" {
  source   = "../../../provisioners/terraform/modules/gcp-apis"
  services = ["sqladmin.googleapis.com"]
}
