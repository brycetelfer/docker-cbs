# docker-cbs
docker image for AhsayCBS v8.3.0.30


## Clone repo and create docker image
    git clone https://github.com/jeffre/docker-cbs.git
    cd docker-cbs
    make docker-image


## Create and run docker container
Quick and dirty:

    docker run -p "80:80" -p "443:443" jeffre/cbs
Using bind mount for important volumes:

    docker run \
        -p "80:80" \
        -p "443:443" \
        -v "$(pwd)/cbs/conf:/cbs/conf" \
        -v "$(pwd)/cbs/download:/cbs/download" \
        -v "$(pwd)/cbs/logs:/cbs/logs" \
        -v "$(pwd)/cbs/system:/cbs/system" \
        -v "$(pwd)/cbs/user:/cbs/user" \
        jeffre/cbs

## Stop running container
    docker stop --time 60 CONTAINER_NAME


## Important Paths
+ **/cbs/conf**: configuration (including ssl certs and user profiles)
+ **/cbs/download**: agent download folder
+ **/cbs/logs**: access logs and context logs
+ **/cbs/system**: policies and system logs 
+ **/cbs/user**: client data


## Environment Variables
+ **CBS_MAC** (Empty): Spoofs mac address which is used by ahsay licensing
(eg: BE:02:A4:D2:14:7F).


## Docker Build Args
+ **APP_HOME** (/cbs): path to install app
+ **UID** (400): id of ahsay user
+ **GID** (400): group id of ahsay user
+ **SOURCE** (http://ahsay-dn.ahsay.com/v8/83030/cbs-nix.tar.gz): URL for CBS
installation tarball


## Features and notes
+ The application runs as the limited user "ahsay" (default 400:400).
+ Catalina is started as a foreground process.
+ `docker stop` (SIGTERM) is caught and triggers `catalina.sh stop` for a
safe shutdown. If your CBS needs more than 10 seconds to stop, be sure to use
the `--time n` flag to prevent docker from prematurely resorting to `kill`.
+ Add support for SSLv2Hello allowing clients on versions less than v6.21.2.0 to connect.
+ Both `/cbs/conf` and `/cbs/download` paths get populated with default files if files
of the same name do not exist prior to the start of the container (docker-entrypoint.sh uses 
`cp --no-clobber`).