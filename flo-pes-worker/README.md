# Flo PES Worker

To run the production server configuration with Docker Compose, you need a valid
Github Token that you will pass to `run_local.sh`:

```
./run_local.sh $DEPLOY_TOKEN
```

This script will build the required Docker images and run them in the background
with Docker Compose.
