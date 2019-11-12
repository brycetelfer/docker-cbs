# docker-cbs
docker image for AhsayCBS v8.3.0.30


## How to
+ Run (quick and dirty):

        docker run -p "80:8080" -p "443:8443" yoff/cbs
+ Run (bind mount important volumes): 

        docker run \
          -p "80:8080" \
          -p "443:8443" \
          -v "$(pwd)/cbs/conf:/cbs/conf" \
          -v "$(pwd)/cbs/download:/cbs/download" \
          -v "$(pwd)/cbs/logs:/cbs/logs" \
          -v "$(pwd)/cbs/system:/cbs/system" \
          -v "$(pwd)/cbs/user:/cbs/user" \
          yoff/cbs
+ Safely stop:

        docker stop --time 60 CONTAINER_NAME


## Important Paths
+ **/cbs/conf**: cbs configuration and client profiles
+ **/cbs/download**: agent download folder 
+ **/cbs/logs**: 
+ **/cbs/system**: 
+ **/cbs/user**: client data


## ENV Variables
+ **CBS_MAC** (Empty): Spoofs mac address which is used by ahsay licensing
(eg: BE:02:A4:D2:14:7F).


## Docker Build Args
+ **APP_HOME** (/cbs): path to install app
+ **UID** (400): id of ahsay user
+ **GID** (400): group id of ahsay user
+ **SOURCE** (http://ahsay-dn.ahsay.com/v8/83030/cbs-nix.tar.gz): URL for CBS
installation tarball


## Features and notes
+ The application runs as the limited user "ahsay" (default 400:400)
+ Catalina is started as a foreground process
+ `docker stop` (SIGTERM) is caught and triggers `catalina.sh stop` for a
safe shutdown. If your CBS needs more than 10 seconds to stop, be sure to use
the `--time n` flag to prevent docker from prematurely resorting to `kill`.


## To-dos
+ Explore allowing SSLv3Hello for agents below v6.21.2.0
