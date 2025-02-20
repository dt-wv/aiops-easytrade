## Generate Dynatrace Access Tokens

Generate a new API access token (***Operator token***) with the following scopes:
```
PaaS - Installer
Access problem and event feed, metrics, and topology
Read settings
Write settings
Ingest metrics
Read entities
Create ActiveGate token
```  
Generate a new API access token (***Data ingest token***) with the following scopes:  
```
Ingest metrics
Ingest logs
Ingest OpenTelemetry traces
```
Generate a new API access token (***Log ingest token***) with the following scopes:  
```
Ingest logs
```
Generate a new API access token (***Bizevent ingest token***) with the following scopes:  
```
Ingest bizevents
Ingest events
Read events
```
Generate a new API access token (***Terraform token***) with the following scopes:  
```
Read configuration
Write configuration
Read settings
Write settings
Create and read synthetic monitors, locations, and nodes
Capture request data
Read credential vault entries
Write credential vault entries
Read network zones
Write network zones
```
Creat a new Dynatrace OAuth Client (***Terraform OAuth Client DI, Secret, URN***) with the following scopes:  
```
settings:objects:read
settings:objects:write
automation:workflows:read
automation:workflows:write
automation:calendars:read
automation:calendars:write
automation:rules:read
automation:rules:write
automation:workflows:admin
document:documents:read
document:documents:write
document:documents:delete
document:direct-shares:read
document:direct-shares:write
document:direct-shares:delete
storage:bizevents:read
storage:bucket-definitions:read
storage:bucket-definitions:write
account-idm-read
account-idm-write
iam-policies-management
account-env-read
```
[See related Dynatrace Operator and Data ingest API token creation documentation](https://docs.dynatrace.com/docs/ingest-from/setup-on-k8s/installation/tokens-permissions#operatorToken)

[See related Dynatrace fluent-bit API token creation documentation](https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-log-ingestion/lma-log-ingestion-via-api/lma-stream-logs-with-fluent-bit)

[See related Dynatrace API Token Creation Documentation](https://docs.dynatrace.com/docs/dynatrace-api/basics/dynatrace-api-authentication#create-token)

[See related Dynatrace API Bizevent Token Creation Documentation](https://docs.dynatrace.com/docs/observe/business-analytics/ba-api-ingest#access-token)

[See related Dynatrace API Terraform Token Creation Documentation](https://docs.dynatrace.com/docs/deliver/configuration-as-code/terraform/teraform-basic-example)

[See related Dynatrace Terraform provider OAuth authentication Documentation](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs)