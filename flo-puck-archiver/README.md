# flo-puck-archiver
## Overview

Monitors and archives old puck telemetry data. 

## Usage

Running without arguments reads the last archived date (from `puck_attributes`) and archives up to the configured limit or the maximum number of days in a single run.

```
Usage: flo-puck-archiver <flags> <subcommand> <subcommand args>

Subcommands:
        commands         list all command names
        help             describe subcommands and their syntax
        test             test dependencies and permissions
```


### Storage

Data is archived into S3. Rows are read by day and all of them grouped, packaged and zipped into the following pattern: `s3://bucket_name/tlm-c/2020/04/01/d8a01d59382c/d8a01d59382c-20200401-0.tar.gz` where the first path uses the last character of the device id to partition the data.

The tarball contains 1 or multiple json files that correspond to a single telemetry reading for the device.

### GO runtime

https://golang.org

On macOS:

- `brew install go`
- Install XCode command line utilities
