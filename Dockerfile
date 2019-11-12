FROM centos:latest
EXPOSE 8080 8443
ARG UID="400"
ARG GID="400"
ARG APP_HOME
ARG SOURCE="${SOURCE:-http://ahsay-dn.ahsay.com/v8/83030/cbs-nix.tar.gz}"
ENV APP_HOME="${APP_HOME:-/cbs}" \
  DEFAULT_FILES="/bootstrap/defaults"
ENV PATH="${PATH}:${APP_HOME}/bin:/bootstrap" \
  CATALINA_PID="${APP_HOME}/cbs.pid"
WORKDIR "${APP_HOME}"


# 'bootstrap' contains the entrypoint.sh, SIGTERM receiver,
# default files, and a pseudo ifconfig
COPY bootstrap/ /bootstrap


# Privileged execution
RUN \
#
#
# Create the limited user and group that will be used to run APP
  groupadd --gid "${GID}" ahsay \
  && useradd --uid "${UID}" --gid "${GID}" --no-create-home "ahsay" \
#
#
# Ensure root paths exist
  && test -d "${DEFAULT_FILES}/conf" || mkdir -p "${DEFAULT_FILES}/conf" \
  && test -d "${APP_HOME}/conf" || mkdir -p "${APP_HOME}/conf" \
  && test -d "${APP_HOME}/system" || mkdir -p "${APP_HOME}/system" \
  && test -d "${APP_HOME}/logs" || mkdir -p "${APP_HOME}/logs" \
  && test -d "${APP_HOME}/user" || mkdir -p "${APP_HOME}/user" \
  && test -d "${APP_HOME}/download" || mkdir -p "${APP_HOME}/download" \
#
#
# Set owner and group to 'ahsay'
  && chown -R ahsay:ahsay "." "/bootstrap" "${DEFAULT_FILES}"


# De-escalate from root
USER ahsay


# Unprivileged execution
RUN \
#
#
# Download and Extact CBS image
  curl -fsSL "${SOURCE}" \
  | tar \
    --exclude="bin/FbdX64" \
    --exclude="bin/FbdX86" \
    --exclude="bin/SosX64" \
    --exclude="bin/cbs-bsd" \
    --exclude="bin/cbs-openbsd" \
    --exclude="bin/cbs-systemd" \
    --exclude="bin/cbs-sysv" \
    --exclude="icons" \
    --exclude="java-linux-x64/lib/amd64/libjfxwebkit.so" \
    --exclude="java-linux-x64/lib/fonts/ipam.ttf" \
    --exclude="java-linux-x64/lib/fonts/uming.ttc" \
    --exclude="java-linux-x64/lib/fonts/UnDotum.ttf" \
    --exclude="java-linux-x64/lib/fonts/VL-Gothic-Regular.ttf" \
    --exclude="java-linux-x64/lib/ext/jfxrt.jar" \
    --exclude="java-linux-x86/lib/i386/libjfxwebkit.so" \
    --exclude="java-linux-x86/lib/fonts/ipam.ttf" \
    --exclude="java-linux-x86/lib/fonts/uming.ttc" \
    --exclude="java-linux-x86/lib/fonts/UnDotum.ttf" \
    --exclude="java-linux-x86/lib/fonts/VL-Gothic-Regular.ttf" \
    --exclude="java-linux-x86/lib/ext/jfxrt.jar" \
    --exclude="lib/FbdX64" \
    --exclude="lib/FbdX86" \
    --exclude="lib/SosX64" \
    --exclude="licenses" \
    --exclude="temp" \
    --exclude="termsofuse" \
    --exclude="tomcat/bin/*.bat" \
    -xzf - \
#
#
# Change default http(s) ports to 8080 and 8443
  && sed -i "conf/server.xml" \
    -e 's|port="80"|port="8080"|' \
    -e 's|port="443"|port="8443"|' \
#
#
# Move default conf files aside for no-clobber copy during docker-entrypoint.sh
  && mv "./conf/"* "${DEFAULT_FILES}/conf"


# Persisting volumes might be useful feature to consider in the future but for
# now it is unjustified
#VOLUME ["${APP_HOME}/conf", "${APP_HOME}/system", "${APP_HOME}/logs", "${APP_HOME}/user", "${APP_HOME}/download"]

ENTRYPOINT ["docker-entrypoint.sh"]
