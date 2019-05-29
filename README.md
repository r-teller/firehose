
# firehose
Project for generating random data for graphing

To get started
1. download this repo to your docker host
    - example:
        - mkdir -r /etc/docker/configs
        - cd /etc/docker/configs
        - git clone https://github.com/r-teller/firehose.git
2. launch your docker container for NGINX 
    - example:
        - docker run --name nginx -p 80:80 -v /etc/docker/configs/firehose/nginx/nginx.conf:/etc/nginx/nginx.conf:ro -v /etc/docker/configs/firehose/nginx/nginx.js:/etc/nginx/nginx.js:ro -d nginx
3. Launching WRK or WRK 2
    - WRK as a binary   
        - For Linux see https://github.com/wg/wrk/wiki/Installing-Wrk-on-Linux
        - For Mac see https://brewinstall.org/install-wrk-on-mac-with-brew/
    - WRK as a container
        - docker run --rm  --net=host -v /etc/docker/configs/firehose/wrk:/data skandyla/wrk -s loadGen.lua http://{NGINX_CONTAINER_IP:PORT}/
    - WRK2 as a container
        - docker run --rm --net=host -v /etc/docker/configs/firehose/wrk:/data 1vlad/wrk2-docker -s /data/loadGen.lua -t4 -c200 -d1s -R2000 http://{NGINX_CONTAINER_IP:PORT}/

Docker build then launch:

Webserver:

docker build --tag firehose-webserver -f Dockerfile-webserver .
docker run --detach --publish=8881:80 --name=firehose-webserver firehose-webserver:latest

Load client:

docker build --tag firehose-wrk -f Dockerfile-wrk .

with randomness:

docker run --rm --net=host --name=client-random firehose-wrk:latest -s /wrk/data/loadGen.lua -t${threads} -c${connections} -d${duration} -R2000 ${target_fqdn}

without randomness:

docker run --rm --net=host --name=client-load firehose-wrk:latest -t${threads} -c${connections} -d${duration} -R2000 ${target_fqdn}

