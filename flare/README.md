# FLARE Containers 22.01.0

## Run Docker Container

```bash
docker run -it --env FORECAST_CODE='forecast_code_here' --env FUNCTION='function_here' --env AWS_DEFAULT_REGION='aws_default_region_here' --env AWS_S3_ENDPOINT='aws_s3_endpoint_here' --env AWS_ACCESS_KEY_ID='aws_access_key_here' --env AWS_SECRET_ACCESS_KEY='aws_secret_access_key_here' flareforecast/flare
```

### Example

```bash
docker run -it --env FORECAST_CODE='https://github.com/FLARE-forecast/FCRE-forecast-code' --env FUNCTION='01_generate_targets.R' --env AWS_DEFAULT_REGION='s3' --env AWS_S3_ENDPOINT='flare-forecast.org' --env AWS_ACCESS_KEY_ID='s3_access_key_here' --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' flareforecast/flare
```

### Environment Parameters

#### FORECAST_CODE

Specifies the forecast codebase Git repository. For instance:

For FCRE: `https://github.com/FLARE-forecast/FCRE-forecast-code`  
For SUNP: `https://github.com/FLARE-forecast/SUNP-forecast-code`

#### FUNCTION

Based on different steps in a forcast workflow, it can be one of the followings:

`01_generate_targets.R`: Downloads the required files  
`02_run_inflow_forecast.R`: Runs inflow forecast  
`03_run_flarer_forecast.R`: Runs FLARE forecast  
`04_visualize.R`: Visualizes the output of the FLARE forecast into graphs

#### AWS_DEFAULT_REGION

Set based on your S3 Cloud information. For CIBR project, it is `s3`.

#### AWS_S3_ENDPOINT

Set based on your S3 Cloud information. For CIBR project, it is `flare-forecast.org`.

#### AWS_ACCESS_KEY_ID

Set based on your S3 Cloud information. For CIBR project, you can ask Dr. Quinn Thomas.

#### AWS_SECRET_ACCESS_KEY

Set based on your S3 Cloud information. For CIBR project, you can ask Dr. Quinn Thomas.

## Build Docker Image

```bash
git clone git@github.com:vahid-dan/FLARE-containers.git
cd FLARE-containers/flare
docker build -t flareforecast/flare .
```

**NOTE:** No need to build the image if no custom image is required. The image is alsready built and uploaded on DockerHub [flareforecast/flare](https://hub.docker.com/repository/docker/flareforecast/flare).
