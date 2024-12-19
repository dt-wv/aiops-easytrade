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

dynatrace_site_reliability_guardianresource "dynatrace_site_reliability_guardian" "easytrade-demo" {
  name        = "easytrade-demo"
  description = "Easytrade DEMO SRG for OrderController service restart"
  tags        = [ "app:easytrade" ]
  objectives {
    objective {
      name                = "OrderService - Memory Available"
      description         = "The requested memory in MB for the Kubernetes workload."
      comparison_operator = "GREATER_THAN_OR_EQUAL"
      dql_query           =<<-EOT
        timeseries mem_t=avg(dt.host.memory.avail.percent), by: {dt.entity.host}, from: now()-5m
        |fieldsadd entityName(dt.entity.host)
        |filter contains(dt.entity.host.name, "credit-card-order")
        | fieldsAdd memavail=arrayAvg(mem_t)
        | fieldsRemove timeframe, dt.entity.host, mem_t, dt.entity.host.name, interval
      EOT
      objective_type      = "DQL"
      target              = 10
      warning             = 15
    }
    objective {
      name                = "OrderService - CPU usage"
      comparison_operator = "LESS_THAN_OR_EQUAL"
      dql_query           =<<-EOT
        timeseries cpuusage_t=avg(dt.host.cpu.usage), by: {dt.entity.host}, from: now()-5m
        |fieldsadd entityName(dt.entity.host)
        |filter contains(dt.entity.host.name, "credit-card-order")
        | fieldsAdd cpuusage=arrayAvg(cpuusage_t)
        | fieldsRemove timeframe, dt.entity.host, cpuusage_t, dt.entity.host.name, interval
      EOT
      objective_type      = "DQL"
      target              = 90
      warning             = 85
    }
    objective {
      name                              = "OrderService - request response time"
      # auto_adaptive_threshold_enabled = false
      comparison_operator               = "LESS_THAN_OR_EQUAL"
      dql_query                         =<<-EOT
        timeseries response=avg(dt.service.request.response_time), by: {dt.entity.service}, from: now() -5m
        | fieldsAdd entityName(dt.entity.service)
        | lookup [fetch dt.entity.service | fieldsAdd tags | expand tags ], sourceField:dt.entity.service, lookupField:id
        //| fieldsAdd lookup.tags
        | filter lookup.tags == "[Environment]DT_RELEASE_PRODUCT:easytrade" and contains(dt.entity.service.name,"Order")
        | fieldsRemove dt.entity.service,lookup.tags, lookup.id, lookup.entity.name
        | fieldsadd responsemax = arrayAvg(response)
        //| fieldsadd responsem = round(responsemax/1000,decimals:0)
        | fieldsRemove dt.entity.service.name, interval, response,timeframe
      EOT
      objective_type                    = "DQL"
      target                            = 80000
      warning                           = 60000
    }
    objective {
      name                              = "OrderService - Free Disk Space"
      # auto_adaptive_threshold_enabled = false
      comparison_operator               = "LESS_THAN_OR_EQUAL"
      dql_query                         =<<-EOT
        timeseries diskspace=avg(dt.host.disk.free), by: {dt.entity.host}, from: now()-5m
        |fieldsadd entityName(dt.entity.host)
        |filter contains(dt.entity.host.name, "credit-card-order")
        | fieldsAdd freedisk=arrayAvg(diskspace)
        | fieldsRemove timeframe, dt.entity.host, diskspace, dt.entity.host.name, interval
      EOT
      objective_type                    = "DQL"
      target                            = 80
      warning                           = 70
    }
    objective {
      name                              = "OrderService - Failure Rate"
      # auto_adaptive_threshold_enabled = false
      comparison_operator               = "LESS_THAN_OR_EQUAL"
      dql_query                         =<<-EOT
        timeseries failureCount_timeseries = sum(dt.service.request.failure_count), by:{dt.entity.service}, from: now()-5m, nonempty: true  | fieldsAdd metricName = "Failed requests"
        | append[
          timeseries {
            operand1 = sum(dt.service.request.failure_count),
            operand2 = sum(dt.service.request.count)
          }, by:{dt.entity.service}, nonempty: true
          | fieldsAdd failureRate_timeseries = operand1[] / operand2[]  * 100
          | fieldsRemove operand1, operand2 | fieldsAdd metricName = "Failure rate"]
          | fieldsAdd failurerate = arrayMax(failureRate_timeseries)
          | lookup [fetch dt.entity.service | fieldsAdd tags | expand tags ], sourceField:dt.entity.service, lookupField:id
        | filter lookup.tags == "[Environment]DT_RELEASE_PRODUCT:easytrade" and contains(lookup.entity.name,"Order")
        
          | fieldsRemove interval, timeframe, failureCount_timeseries, metricName, dt.entity.service, failureRate_timeseries, lookup.entity.name, lookup.tags, lookup.id
          | filter isNotNull(failurerate)
      EOT
      objective_type                    = "DQL"
      target                            = 90
      warning                           = 80
    }
  }
}