if [ $(docker-machine status default) = "Stopped" ]; then
  echo "Starting VM with 'docker-machine start default'"
  docker-machine start default || exit 1
fi
eval $(docker-machine env default)
IP_ADDRESS=$(docker-machine ip default)
