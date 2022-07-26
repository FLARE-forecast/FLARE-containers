# FLARE Containers

The purpose of this project is to run FLARE forecast with a docker container. It supports native S3 integration, and the output gets stored on S3 storage. If the use of S3 is enabled in the configurations, S3 access information is required.

## Run Docker Container

### Quick Start

To run in "container" mode without Apache OpenWhisk or IBM Cloud Functions:

```bash
docker run --env RUN_MODE='container' \
           --env FORECAST_CODE_REPO='forecast_code_repo_here' \
           --env FORECAST_CODE_BRANCH='forecast_code_branch_tag_here' \
           --env FORECAST_CODE_COMMIT='forecast_code_commit_here' \
           --env CONFIG_SET='config_set_here' \
           --env FUNCTION='function_here' \
           --env CONFIGURE_RUN='configure_run_file_here' \
           --env AWS_DEFAULT_REGION='s3_default_region_here' \
           --env AWS_S3_ENDPOINT='s3_endpoint_here' \
           --env USE_HTTPS='TRUE or FALSE' \
           --env AWS_ACCESS_KEY_ID='s3_access_key_here' \
           --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' \
           --entrypoint '/root/flare-run-container.sh' \
           --rm flareforecast/flare
```

To run in "serverless" mode with Apache OpenWhisk or IBM Cloud Functions, you should not set `entrypoint` for `docker run` command:

```bash
docker run --env RUN_MODE='serverless' \
           --env FORECAST_CODE_REPO='forecast_code_repo_here' \
           --env FORECAST_CODE_BRANCH='forecast_code_branch_tag_here' \
           --env FORECAST_CODE_COMMIT='forecast_code_commit_here' \
           --env CONFIG_SET='config_set_here' \
           --env FUNCTION='function_here' \
           --env CONFIGURE_RUN='configure_run_file_here' \
           --env AWS_DEFAULT_REGION='s3_default_region_here' \
           --env AWS_S3_ENDPOINT='s3_endpoint_here' \
           --env USE_HTTPS=FALSE \
           --env AWS_ACCESS_KEY_ID='s3_access_key_here' \
           --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' \
           --rm flareforecast/flare
```

### Example

For authorized CIBR users to run FCRE forecasts in "container" mode:

```bash
docker run --env FORECAST_CODE_REPO='https://github.com/FLARE-forecast/FCRE-forecast-code' \
           --env FORECAST_CODE_BRANCH='latest' \
           --env CONFIG_SET='default' \
           --env FUNCTION='0' \
           --env CONFIGURE_RUN='configure_run.yml' \
           --env AWS_DEFAULT_REGION='s3' \
           --env AWS_S3_ENDPOINT='flare-forecast.org' \
           --env USE_HTTPS=TRUE \
           --env AWS_ACCESS_KEY_ID='s3_access_key_here' \
           --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' \
           --entrypoint '/root/flare-run-container.sh' \
           --rm flareforecast/flare
```

### Run without S3 with Shared Volume

If `use_s3: FALSE` in `configure_run.yml`, the workflow stores the outputs locally in the container instead of writing them to S3 storage.

**NOTE:** For CIBR project, forecast code needs to access the S3 storage to read NOAA forecasts. So, S3 configurations including `AWS_DEFAULT_REGION`, `AWS_S3_ENDPOINT`, and `USE_HTTPS` are still needed for running the container but, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are not required.

To access the container output, we can mount it as a shared volume on the host. For instance, it will be store in `/root/forecast-code` in the following example:

```bash
docker run -volume ~:/root/flare-containers \
           --env FORECAST_CODE_REPO='forecast_code_repo_here' \
           --env FORECAST_CODE_BRANCH='forecast_code_branch_tag_here' \
           --env FORECAST_CODE_COMMIT='forecast_code_commit_here' \
           --env CONFIG_SET='config_set_here' \
           --env FUNCTION='function_here' \
           --env CONFIGURE_RUN='configure_run_file_here' \
           --env AWS_DEFAULT_REGION='s3_default_region_here' \
           --env AWS_S3_ENDPOINT='s3_endpoint_here' \
           --env USE_HTTPS='TRUE or FALSE' \
           --env AWS_ACCESS_KEY_ID='s3_access_key_here' \
           --env AWS_SECRET_ACCESS_KEY='s3_secret_key_here' \
           --rm flareforecast/flare
```

### Environmental Variables

#### FORECAST_CODE_REPO

**Required**

Specifies the forecast codebase Git repository to be used. For instance, for CIBR project:

`https://github.com/FLARE-forecast/FCRE-forecast-code`: For FCRE  
`https://github.com/FLARE-forecast/SUNP-forecast-code`: For SUNP

#### FORECAST_CODE_BRANCH

**Optional**

**Default Value:** Default branch of the repository (Usually `master` or `main`)

Specifies the branch or tag of the `FORECAST_CODE_REPO` repository to be used.

#### FORECAST_CODE_COMMIT

**Optional**

**Default Value:** Latest commit (Head) of the specified branch of the repository

Specifies the commit of the `FORECAST_CODE_REPO` repository to be used.

#### CONFIG_SET

**Optional**

**Default Value:** `default`

Specifies the configuration set to be used for the forecast. The default value is `default` which loads the scripts from `workflows/default` and the configurations from `configurations/default` directory. Modified code and configuration set can be placed in new directories under `workflows` and `configuration` respectively.

#### FUNCTION

**Optional**

**Default Value:** `0`

Based on different steps in a forecast workflow, it can be one of the following:

`0`: Runs the whole workflow for a full forecast  
`1`: Downloads the required files to run forecast  
`2`: Runs inflow forecast  
`3`: Runs FLARE forecast  
`4`: Visualizes the output of the FLARE forecast into graphs

#### CONFIGURE_RUN

**Optional**

**Default Value:** `configure_run.yml`

Specifies the name of the run-time configuration file. This file should be located inside the configuration set directory.

#### AWS_DEFAULT_REGION

**Optional**

**Default Value:** NULL

Set based on S3 cloud access information. For CIBR project, it is `s3`.

#### AWS_S3_ENDPOINT

**Required**

Set based on S3 cloud access information. For CIBR project, it is `flare-forecast.org`.

#### USE_HTTPS

**Optional**

**Default Value:** `FALSE`

Set TRUE or FALSE to enable or disable using HTTPS to access the AWS_S3_ENDPOINT. For CIBR project, it is `TRUE`.

#### AWS_ACCESS_KEY_ID

**Required**

Set based on S3 cloud access information. For CIBR project, ask Dr. Quinn Thomas.

#### AWS_SECRET_ACCESS_KEY

**Required**

Set based on S3 cloud access information. For CIBR project, ask Dr. Quinn Thomas.

### How to Set and Test S3 Configurations

To make sure your S3 config works fine, you can try it with the following R script:

```
# 'AWS_DEFAULT_REGION' can be left NULL. The S3 URL should be set as 'AWS_END_POINT' without 'http://' or 'https://'.
# Examples:
#Sys.setenv('AWS_DEFAULT_REGION' = '', 'AWS_S3_ENDPOINT' = 's3.flare-forecast.org', 'AWS_ACCESS_KEY_ID' = 'access_key_id', 'AWS_SECRET_ACCESS_KEY' = 'secret_key')
#Sys.setenv('AWS_DEFAULT_REGION' = '', 'AWS_S3_ENDPOINT' = '35.85.48.109', 'AWS_ACCESS_KEY_ID' = 'access_key_id', 'AWS_SECRET_ACCESS_KEY' = 'secret_key')
#Sys.setenv('AWS_DEFAULT_REGION' = '', 'AWS_S3_ENDPOINT' = 'ec2-35-85-48-109.us-west-2.compute.amazonaws.com', 'AWS_ACCESS_KEY_ID' = 'access_key_id', 'AWS_SECRET_ACCESS_KEY' = 'secret_key')
#Sys.setenv('AWS_DEFAULT_REGION' = '', 'AWS_S3_ENDPOINT' = 'tacc.jetstream-cloud.org:8080', 'AWS_ACCESS_KEY_ID' = 'access_key_id', 'AWS_SECRET_ACCESS_KEY' = 'secret_key')

install.packages('aws.s3')
library('aws.s3')

# To enforce HTTPS, should be set to TRUE
Sys.setenv('USE_HTTPS' = FALSE)

Sys.setenv('AWS_DEFAULT_REGION' = '', 'AWS_S3_ENDPOINT' = 'play.min.io', 'AWS_ACCESS_KEY_ID' = 'Q3AM3UQ867SPQQA43P2F', 'AWS_SECRET_ACCESS_KEY' = 'zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG')

# List all the buckets
aws.s3::bucketlist(region = Sys.getenv('AWS_DEFAULT_REGION'), use_https = as.logical(Sys.getenv('USE_HTTPS')))

# List a specific bucket
aws.s3::get_bucket(bucket = 'drivers', region = Sys.getenv('AWS_DEFAULT_REGION'), use_https = as.logical(Sys.getenv('USE_HTTPS')))
```

## Build Docker Image

```bash
git clone git@github.com:FLARE-forecast/FLARE-containers.git
cd FLARE-containers
docker build -t flareforecast/flare -f flare/Dockerfile .
```

**NOTE:** No need to build image if no custom image is required. The image is already built and uploaded to DockerHub [flareforecast/flare](https://hub.docker.com/repository/docker/flareforecast/flare).
