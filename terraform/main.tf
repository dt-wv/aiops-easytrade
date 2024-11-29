terraform {
    required_providers {
        dynatrace = {
            version = "~> 1.0"
            source = "dynatrace-oss/dynatrace"
        }
    }
}

resource "dynatrace_management_zone_v2" "create_mgmt_zone" {
name = "easytrade"
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
            tag = "[Environment]DT_RELEASE_PRODUCT:easytrade"
            key       = "SERVICE_TAGS"
            operator  = "EQUALS"
          }
        }
      }
    }
}
}

resource "dynatrace_frequent_issues" "set_frequent_issues" {
  detect_apps = false
  detect_txn = false
  detect_infra = false
}

resource "dynatrace_metric_events" "create_metric_event" {
  enabled                    = true
  event_entity_dimension_key = "dt.entity.service"
  summary                    = "Service 500 errors"
  event_template {
    description   = "The {metricname} value was {alert_condition} normal behavior."
    davis_merge = false
    event_type    = "ERROR"
    title         = "Service 500 Errors"
  }
  model_properties {
    type               = "STATIC_THRESHOLD"
    alert_condition    = "ABOVE"
    alert_on_no_data   = false
    dealerting_samples = 3
    samples            = 3
    threshold          = 1
    violating_samples  = 3
  }
  query_definition {
    type        = "METRIC_KEY"
    aggregation = "AVG"
    metric_key  = "builtin:service.errors.fivexx.rate"
    entity_filter {
      dimension_key = "dt.entity.service"
      conditions{
        condition{
            type="TAG" 
            operator="EQUALS"
            value="[Environment]DT_RELEASE_PRODUCT:easytrade"
        }
      }
    }
  }  
}