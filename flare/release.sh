set -ex
# DockerHub username
USERNAME=flareforecast
# Image name
IMAGE=flare

# Ensure we're up to date
git pull

# Bump version
/usr/bin/docker run --rm -v "$PWD":/app treeder/bump patch
version=`cat VERSION`
echo "version: $version"

# Run build
./build.sh
echo "Build finished"

# Tag it
git add -A
git commit -m "version $version"
git tag -a "$version" -m "version $version"
git push
git push --tags
/usr/bin/docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$version
echo "Tags pushed"

# Push it
/usr/bin/docker push $USERNAME/$IMAGE:latest
/usr/bin/docker push $USERNAME/$IMAGE:$version
echo "Images pushed"
