# kit

> _kit - a set of things, such as tools or clothes, used for a particular purpose or activity._

A downloader and installer for binary packages from HTTP(s) or Github Release endpoints
that checks if currently installed, verifies correct version and if needed downloads
from the remote endpoint and verifies the SHA upon download.

### Why?

I want a single way to handle installation and updates of binary tools on Mac and Linux
environments, using a tool that has no dependencies beyond the binary itself.

With the advent of Golang and Rust, more daily tools are moving to compiled binaries
and back away from scripting languages (with their associated complexity of dependency
management). On a Mac, homebrew can install and some of them. On Linux this is a manual
process requiring custom scripts. `kit` fills that void and leverages HTTPS or Github
Release endpoints to make it trivial to install and manage versions of published
binary package.

`kit` is not intended to manage more complicated package management situations such as
package dependencies or complex packages. It is intended for packages that consist of
one or more binaries that are dependency free and statically compiled.

## Installation

Convenient method:

```
wget --content-disposition https://bin.suyash.io/zph/kit -O ~/bin/kit && chmod +x ~/bin/kit
```

Manual method:

Download from https://github.com/zph/kit/releases for your architecture. Then make it
executable and available on your $PATH.

## Usage

There is a shorthand syntax for using Github Release endpoints:

```
$ kit -i stedolan/jq -o ~/bin
$ kit -i stedolan/jq#jq-1.6 -o ~/bin
```

Where the first example will get `latest` and the second example will get a specific
release tag.

For tar.gz with multiple binaries, specify the binaries to find inside the archive
and they will be copied out.

```
$ kit --install https://get.gravitational.com/teleport-v3.0.1-darwin-amd64-bin.tar.gz -o dist --binaries teleport,tsh,tctl
```

See examples for configuration mechanism beyond the commandline flags. Using a config
file is faster because each binary update/install is run in its own fiber.

## Contributing

1. Fork it (<https://github.com/zph/kit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Zander Hill](https://github.com/zph) - creator and maintainer
