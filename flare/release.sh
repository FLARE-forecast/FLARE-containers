set -ex
# DockerHub username
USERNAME=flareforecast
# Image name
IMAGE=flare

# Ensure we're up to date
git pull

# Bump version
docker run --rm -v "$PWD":/app treeder/bump patch
version=`cat VERSION`
echo "version: $version"

# Run build
./build.sh

# Tag it
git add -A
git commit -m "version $version"
git tag -a "$version" -m "version $version"
git push
git push --tagsdocker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$version

# Push it
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version
