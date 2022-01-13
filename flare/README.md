# FLARE Containers 22.01.0

The purpose of this project is to run FLARE forecast with a docker container. It supports native S3 integration, and the output gets stored on S3 storage. If the use of S3 is enabled in the configurations, S3 access information is required.

## Run Docker Container

### Quick Start

Set the environment variables ans run the following command:

```bash
docker run -it --env FORECAST_CODE='forecast_code_here' \
               --env FUNCTION='function_here' \
               --env AWS_DEFAULT_REGION='s3_default_region_here' \
               --env AWS_S3_ENDPOINT='s3_endpoint_here' \
               --env AWS_ACCESS_KEY_ID='s3_access_key_here' \
               --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' \
               --rm flareforecast/flare
```

### Example

For authorized CIBR users to run FCRE forecasts:

```bash
docker run -it --env FORECAST_CODE='https://github.com/FLARE-forecast/FCRE-forecast-code' \
               --env FUNCTION='01_generate_targets.R' \
               --env AWS_DEFAULT_REGION='s3' \
               --env AWS_S3_ENDPOINT='flare-forecast.org' \
               --env AWS_ACCESS_KEY_ID='s3_access_key_here' \
               --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' \
               --rm flareforecast/flare
```

### Run with Shared Volume and without S3

If `use_s3: FALSE` in `configure_run.yml`, the workflow stores the outputs locally in the container instead of writing them to S3 storage.

**NOTE:** For CIBR project, it still needs to access the S3 storage to read NOAA forecasts. So, S3 credentials are still needed for running the container.

To access the container output, we can mount it as a shared volume on the host. For instance, it will be store in `~/forecast-code` in the following example:

```bash
docker run -it -v ~:/root/flare-containers \
               --env FORECAST_CODE='forecast_code_here' \
               --env FUNCTION='function_here' \
               --env AWS_DEFAULT_REGION='s3_default_region_here' \
               --env AWS_S3_ENDPOINT='s3_endpoint_here' \
               --env AWS_ACCESS_KEY_ID='s3_access_key_here' \
               --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' \
               --rm flareforecast/flare
```

### Environment Parameters

#### FORECAST_CODE

Specifies the forecast codebase Git repository. For instance, for CIBR project:

`https://github.com/FLARE-forecast/FCRE-forecast-code`: For FCRE  
`https://github.com/FLARE-forecast/SUNP-forecast-code`: For SUNP

#### FUNCTION

Based on different steps in a forecast workflow, it can be one of the following:

`01_generate_targets.R`: Downloads the required files to run forecast  
`02_run_inflow_forecast.R`: Runs inflow forecast  
`03_run_flarer_forecast.R`: Runs FLARE forecast  
`04_visualize.R`: Visualizes the output of the FLARE forecast into graphs

#### AWS_DEFAULT_REGION

Set based on S3 cloud access information. For CIBR project, it is `s3`.

#### AWS_S3_ENDPOINT

Set based on S3 cloud access information. For CIBR project, it is `flare-forecast.org`.

#### AWS_ACCESS_KEY_ID

Set based on S3 cloud access information. For CIBR project, ask Dr. Quinn Thomas.

#### AWS_SECRET_ACCESS_KEY

Set based on S3 cloud access information. For CIBR project, ask Dr. Quinn Thomas.

## Build Docker Image

```bash
git clone git@github.com:vahid-dan/FLARE-containers.git
cd FLARE-containers/flare
docker build -t flareforecast/flare .
```

**NOTE:** No need to build image if no custom image is required. The image is alsready built and uploaded on DockerHub [flareforecast/flare](https://hub.docker.com/repository/docker/flareforecast/flare).
