# flo-insta-tracing

## Standardized Instana instrumentation for flo
=====================================================

This module contains instrumentation code for using Instana go-sensor and related packages.  It also facilitates the context propagation of Kafka producers and consumers.

## Usage
------------

### as Go private module
```bash
$ GOPRIVATE=gitlab.com/ctangfbwinn/flo-insta-tracing go get gitlab.com/ctangfbwinn/flo-insta-tracing
```
### as git subtree and Go workspace
#### to add subtree [(reference)](https://www.youtube.com/watch?v=t3Qhon7burE)
```bash
git remote add -f flo-insta-tracing https://gitlab.com/ctangfbwinn/flo-insta-tracing.git
git subtree add --squash --prefix src/flo-insta-tracing flo-insta-tracing main

go work init
go work use flo-insta-tracing
go work use .
```

#### to push changes from submodule to its repo
```bash
git subtree push --prefix src/flo-insta-tracing flo-insta-tracing main
```

#### to get new changes from submodule's repo
```bash
git subtree pull --squash --prefix src/flo-insta-tracing flo-insta-tracing main
```
