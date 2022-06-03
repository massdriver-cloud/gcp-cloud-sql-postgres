
module "apis" {
  source   = "./modules/gcp-apis"
  services = ["sqladmin.googleapis.com"]
}
