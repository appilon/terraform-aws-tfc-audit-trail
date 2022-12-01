# TFC Audit Trail Importer for AWS
This is a Terraform No-Code ready module that will deploy a docker container on Amazon ECS Fargate running [Vector](https://vector.dev/), to import [TFC Audit Trails](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails).

## Supported Services
* CloudWatch Logs

## Tuning
The Vector based HTTP client understandably can only poll 1 endpoint, it cannot be configured with logic such as pagination. With that in mind, in order to ensure no events are missed, it's important to configure the appropriate options:

* `var.scrape_interval_secs`: The interval Vector will wait between page requests (default: `30`).
* `var.page_size`: The max number of events to return from the TFC API. Try and keep in mind the longer the scrape interval, the more events have transpired, ensuring no events are missed involves the right combination of scrape interval and page size (default: `1000`).
* `var.deduplication_cache_size`: Vector features an LRU cache that prevents duplicate events from being delivered. The cache is not persisted between Vector restarts. This value should probably be at least as large as the page size (default: `5000`).

## Known Issues
Vector has a few special top level fields in the [log event schema](https://vector.dev/docs/about/under-the-hood/architecture/data-model/log/) that may get special treatment, particulary the `timestamp` field. The CloudWatch Logs Sink appears to remove the timestamp from the log event and set it as the CloudWatch Log timestamp, the issue is that for some reason the timestamp is incorrect within CloudWatch Logs (furthermore it's useful for future dataprocessing if the timestamp remains within the object structure). It appears to be the timestamp at time of push, resulting in data-loss of the actual audit log timestamp. An [issue](https://github.com/vectordotdev/vector/issues/15346) has been filed, as a workaround, `timestamp` has been copied to a newly named field `original_timestamp`.