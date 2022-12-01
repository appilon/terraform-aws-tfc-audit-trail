# TFC Audit Trail Importer for AWS
This is a Terraform No-Code Module that will deploy a docker container on Amazon ECS Fargate running [Vector](https://vector.dev/), to import [TFC Audit Trails](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails).

## Supported Services
* CloudWatch Logs

## Tuning
The Vector based HTTP client understandably can only poll 1 endpoint, it cannot be configured with logic such as pagination. With that in mind, in order to ensure no events are missed, it's important to configure the appropriate options:

* `var.scrape-interval-secs`: The interval Vector will wait between page requests (default: `30`).
* `var.page-size`: The max number of events to return from the TFC API. Try and keep in mind the longer the scrape interval, the more events have transpired, ensuring no events are missed involves the right combination of scrape interval and page size (default: `1000`).
* `var.deduplication-cache-size`: Vector features an LRU cache that prevents duplicate events from being delivered. The cache is not persisted between Vector restarts. This value should probably be at least as large as the page size (default: `5000`).
