FROM centos:latest
EXPOSE 80 443
ARG UID="400"
ARG GID="400"
ARG APP_HOME
ARG SOURCE="${SOURCE:-http://ahsay-dn.ahsay.com/v8/83030/cbs-nix.tar.gz}"
ENV APP_HOME="${APP_HOME:-/cbs}" \
  DEFAULT_FILES="/bootstrap/defaults"
ENV PATH="${PATH}:${APP_HOME}/bin:/bootstrap" \
  CATALINA_PID="${APP_HOME}/cbs.pid"
WORKDIR "${APP_HOME}"


# 'bootstrap' contains docker-entrypoint.sh, SIGTERM receiver,
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
  && test -d "${DEFAULT_FILES}/download" || mkdir -p "${DEFAULT_FILES}/download" \
  && test -d "${APP_HOME}/conf" || mkdir -p "${APP_HOME}/conf" \
  && test -d "${APP_HOME}/download" || mkdir -p "${APP_HOME}/download" \
  && test -d "${APP_HOME}/logs" || mkdir -p "${APP_HOME}/logs" \
  && test -d "${APP_HOME}/system" || mkdir -p "${APP_HOME}/system" \
  && test -d "${APP_HOME}/user" || mkdir -p "${APP_HOME}/user" \
#
#
# Set owner and group to 'ahsay'
  && chown -R ahsay:ahsay "." "/bootstrap" "${DEFAULT_FILES}" \
#
#
# Download and extract CBS image (as ahsay)
  && su ahsay -c ' \
    curl -fsSL "'"${SOURCE}"'" \
    | tar \
      --anchored \
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
  ' \
#
#
# Add SSLv2Hello (allow clients below v6.21.2.0 to connect)
  && sed -i "conf/server.xml" \
    -e 's|protocols="TLSv1+TLSv1.1+TLSv1.2"|protocols="SSLv2Hello+TLSv1+TLSv1.1+TLSv1.2"|' \
#
#
# Move 'conf' and 'download' files aside for no-clobber copy during docker-entrypoint.sh
  && mv "./conf/"* "${DEFAULT_FILES}/conf" \
  && mv "./download/"* "${DEFAULT_FILES}/download" \
#
#
# Permit tomcat to listen on ports < 1024
  && setcap cap_net_bind_service=+ep java-linux-x64/bin/java \
  && setcap cap_net_bind_service=+ep java-linux-x86/bin/java \
  && sharedir=$(find java-*/lib -name "libjli.so" | awk '{print substr($0, 0, length($0)-10)}') \
  && echo "$sharedir" > /etc/ld.so.conf.d/java-libjli.conf \
  && ldconfig -v


# De-escalate from root
USER ahsay


# Persisting volumes might be useful feature to consider in the future but for
# now it is unjustified
#VOLUME ["${APP_HOME}/conf", "${APP_HOME}/system", "${APP_HOME}/logs", "${APP_HOME}/user", "${APP_HOME}/download"]

ENTRYPOINT ["docker-entrypoint.sh"]
