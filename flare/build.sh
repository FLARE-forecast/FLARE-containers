set -ex

# DockerHub username
USERNAME=flareforecast

# Image name
IMAGE=flare

docker build -t $USERNAME/$IMAGE:latest .

