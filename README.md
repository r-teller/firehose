# firehose
Project for generating random data for graphing

To get started
1. download this repo to your docker host
    - example:
        - mkdir -r /etc/docker/configs
        - cd /etc/docker/configs
        - git clone https://github.com/r-teller/firehose.git
2. launch your docker container
    - example:
        - docker run --name nginx -p 80:80 -v /etc/docker/configs/firehose/nginx/nginx.conf:/etc/nginx/nginx.conf:ro -v /etc/docker/configs/firehose/nginx/nginx.js:/etc/nginx/nginx.js:ro -d nginx

Launching WRK
For Linux see https://github.com/wg/wrk/wiki/Installing-Wrk-on-Linux
For Mac see https://brewinstall.org/install-wrk-on-mac-with-brew/
