#!/bin/bash


# Copy in default files if not already present
cp --recursive --no-clobber "${DEFAULT_FILES}"/* "${APP_HOME}"


# Change call to catalina.sh to use 'run' instead of 'start' (prevent 
# daemonizing), remove pipe to /dev/null, 
sed -i "${APP_HOME}/bin/startup.sh" \
  -e 's|nohup sh "\([^"]*\).*|"\1" run|g'


# Run Addon scripts
if [[ -n ${ADDON_SCRIPT} ]]; then
  source "${ADDON_SCRIPT}"
fi


if [[ "${#}" == 0 ]]; then
  # Starts APP within traps that will help to kill it safely
  source "/bootstrap/app-trap.sh"
else
  exec "${@}"
fi
