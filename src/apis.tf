
module "apis" {
  source   = "github.com/massdriver-cloud/terraform-modules//gcp-enable-apis?ref=c336d59"
  services = ["sqladmin.googleapis.com"]
}
