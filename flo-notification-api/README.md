# Flo Scala Service Template

This is a template project intended to serve as base for new applications.

## Pre-requisites
* Docker
* Docker Compose

## How to run the server?

### Development Mode

```$> make run-dev```

This will:
1. Create a Docker container.
2. Download all dependencies inside the container.
3. Launch a local server inside the container with the corresponding ports mapped to the host (including the debugging port: 5005).
4. Watch the filesystem for changes in the source code. Upon a change, the server will automatically reload.

To know how to configure IntelliJ idea debugger see: http://codingphd.com/2016/07/22/remote-debug-with-sbt-and-intellij-idea/

### Production

```$> make run-build```

This will:
1. Will run the build task and generate a fat jar.

```$> make run-prod```

This will:
1. Will run the fat jar generated on build task.

## How to run tests?

### Watch mode

  ```$> make run-tests```

This will run inside a Docker container (if there is a container already running, it will just run the tests inside in order to avoid launching a new one).
(You will be able to debug connecting to debugging port: 5005)

## What else is inside this template?


### Makefile
As the avid reader might have noticed, we are using `Makefile`. Run `make help` (or just `make`) to get a list of all the available targets.