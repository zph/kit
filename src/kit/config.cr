CONFIG = YAML.parse <<-END
---
binaries:
  teleport:
    general:
      version_cmd: version
      output: data
      binaries:
      - teleport
      - tctl
      - tsh
    platform:
      darwin:
        link: https://get.gravitational.com/teleport-v3.0.1-darwin-amd64-bin.tar.gz
        version: v3.0.1
        sha256: 755abfa6942c5b2fbfd66eb59de0bdd75aea953369f56dd12fcddd0eab7e7d00
  jq:
    general:
      version_cmd: -V
      output: data
      binaries:
      - jq
      post_install:
      - chmod +x jq
    platform:
      darwin:
        link: github://stedolan/jq#jq-1.6
        version: jq-1.6
        sha256: 5c0a0a3ea600f302ee458b30317425dd9632d1ad8882259fcaf4e9b868b2b1ef
  aws-vault:
    general:
      version_cmd: "--version"
      output: data
      binaries:
      - aws-vault
      post_install:
      - chmod +x aws-vault
    platform:
      darwin:
        # link: https://github.com/99designs/aws-vault/releases/download/v4.4.1/aws-vault-darwin-amd64
        link: github://99designs/aws-vault#v4.4.1
        version: v4.4.1
        sha256: 6c84a00b919629f153ad43a0889cc8f8d67708cfc85cce8bd6e98a57706368b0
END
