``` playground
require "./src/kit.cr"
Kit::Adapters::Github::API.download_link("stedolan", "jq", "jq-1.6", Kit::OS::Platform::Darwin)
```
