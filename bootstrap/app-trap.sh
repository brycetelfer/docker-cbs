#!/bin/bash


# Stop catalina properly to avoid corrupting Profile.xml files and then exit
#   the container with exitcode 143 (128 + 15)


catalina_stop () {
  echo "Running Catalina Stop"
  pgrep --uid "ahsay" -f "java" > "${CATALINA_PID}"
  "${APP_HOME}/bin/shutdown.sh"
  exit 143;
}


# Intercept SIGTERM (issued from `docker stop`) then kill `tail -f` and run
#   `catalina_stop`
trap 'kill ${!}; catalina_stop' SIGTERM


# Start APP and get its PID
"${APP_HOME}/bin/startup.sh" &
pid="$!"


# Wait forever
while true; do
  tail -f "/dev/null" & wait ${!}
done
