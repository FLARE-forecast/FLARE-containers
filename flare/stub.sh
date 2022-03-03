#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Read value from json and set environment variables
export FORECAST_CODE=$(echo $1 | jq -r '."forecast_code"')
export CONFIG_SET=$(echo $1 | jq -r '."config_set"')
export FUNCTION=$(echo $1 | jq -r '."function"')
export USE_HTTPS=$(echo $1 | jq -r '."use_https"')
export AWS_DEFAULT_REGION=$(echo $1 | jq -r '."aws_default_region"')
export AWS_S3_ENDPOINT=$(echo $1 | jq -r '."aws_s3_endpoint"')
export AWS_ACCESS_KEY_ID=$(echo $1 | jq -r '."aws_access_key_ID"')
export AWS_SECRET_ACCESS_KEY=$(echo $1 | jq -r '."aws_secret_access_key"')
export SIM_NAME=$(echo $1 | jq -r '."sim_name"')
# Run flare-run-container.sh
/root/flare-run-container.sh
# Return json parameters
if [ "$FUNCTION" -lt 4 ] && [ "$FUNCTION" -gt 0 ]; then
  NEXT_FUNCTION=`expr $FUNCTION + 1`
  result="{ \"forecast_code\": \"$FORECAST_CODE\", \
            \"config_set\": \"$CONFIG_SET\", \
            \"function\": \"$NEXT_FUNCTION\", \
            \"use_https\": \"$USE_HTTPS\", \
            \"aws_default_region\": \"$AWS_DEFAULT_REGION\", \
            \"aws_s3_endpoint\": \"$AWS_S3_ENDPOINT\", \
            \"aws_access_key_ID\": \"$AWS_ACCESS_KEY_ID\", \
            \"aws_secret_access_key\": \"$AWS_SECRET_ACCESS_KEY\", \
            \"sim_name\": \"$SIM_NAME\"}"
else
  result='{ "result": "Completed!" }'
fi
echo "${result}"
