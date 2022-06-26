set -ex

# DockerHub username
USERNAME=flareforecast

# Image name
IMAGE=flare

cd ..
docker build -t $USERNAME/$IMAGE:latest -f flare/Dockerfile .

