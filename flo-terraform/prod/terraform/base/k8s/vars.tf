variable "public_subnet_count" {
    default = 1
}

variable "private_subnet_count" {
  default = 1
}

variable "cidr_block" {
  
}


variable "kops_bucket_name" {
  
}

variable "tag_env" {
  
}

variable "route53_domain" {
  
}

variable "use_route53_ns_record" {

}

variable "cloudflare_domain_ns" {
    default = ""

}
variable "cloudflare_domain_name" {
    default = ""

}

variable "cloudflare_domain" {
  default = ""
}
variable "cloudflare_cname_record_address" {
    default = ""

}


variable "route53_record_type" {
  default = "NS"
}

variable "route53_record_count" {
  default = 1
}


variable "tag_organisation" {
  
}

variable "tag_deployment" {
  
}

variable "tag_deployment_code" {
  
}

variable "tag_kubernetes_cluster" {
  
}
variable "tag_project" {
  
}

variable "tag_name" {
  
}


variable "domain" {
  
}
