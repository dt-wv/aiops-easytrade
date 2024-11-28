terraform {
    required_providers {
        dynatrace = {
            version = "~> 1.0"
            source = "dynatrace-oss/dynatrace"
        }
    }
}

resource "dynatrace_management_zone_v2" "create_mgmt_zone" {
name = "easytrade2"
rules {
    rule {
      type            = "ME"
      enabled         = true
      entity_selector = ""
      attribute_rule {
        entity_type                 = "SERVICE"
        service_to_host_propagation = true
        service_to_pgpropagation    = true
        attribute_conditions {
          condition {
            entity_id = "[Environment]DT_RELEASE_PRODUCT:easytrade"
            key       = "SERVICE_TAGS"
            operator  = "EQUALS"
          }
        }
      }
    }
}
}