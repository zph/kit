``` playground
require "./src/kit.cr"
Kit::Github::API.download_link("stedolan", "jq", "jq-1.6", Kit::OS::Platform::Darwin)
```
