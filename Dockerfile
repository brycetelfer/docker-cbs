# CREATE COMMON IMAGE
FROM centos:latest as common
ARG UID="400"
ARG GID="400"
ARG APP_HOME="/cbs"
ARG INSTALLER="http://ahsay-dn.ahsay.com/v8/83030/cbs-nix.tar.gz"
ARG HOTFIXES
ENV UID="${UID}" GID="${GID}" UID="${UID}" APP_HOME="${APP_HOME}" \
  INSTALLER="${INSTALLER}" HOTFIXES="${HOTFIXES}" DEFAULT_FILES="/bootstrap/defaults"
ENV PATH="${PATH}:${APP_HOME}/bin:/bootstrap" CATALINA_PID="${APP_HOME}/cbs.pid"
WORKDIR "${APP_HOME}"

# Create a limited user to handle `curl` as well as running the final image
RUN groupadd --gid "${GID}" ahsay \
  && useradd --uid "${UID}" --gid "${GID}" --no-create-home "ahsay"



# CREATE BUILDER IMAGE
FROM common as builder

# Install the needful
RUN yum install -y unzip

# Ensure base paths exist
RUN test -d "${DEFAULT_FILES}/conf" || mkdir -p "${DEFAULT_FILES}/conf" \
  && test -d "${DEFAULT_FILES}/download" || mkdir -p "${DEFAULT_FILES}/download" \
  && test -d "${APP_HOME}/conf" || mkdir -p "${APP_HOME}/conf" \
  && test -d "${APP_HOME}/download" || mkdir -p "${APP_HOME}/download" \
  && test -d "${APP_HOME}/logs" || mkdir -p "${APP_HOME}/logs" \
  && test -d "${APP_HOME}/system" || mkdir -p "${APP_HOME}/system" \
  && test -d "${APP_HOME}/user" || mkdir -p "${APP_HOME}/user"

# 'bootstrap' contains docker-entrypoint.sh, SIGTERM receiver,
# default files, and a pseudo ifconfig
COPY bootstrap/ /bootstrap

# Copy in cbs-nix and hotfixes (eg: cbs-nix.tar.gz and 
# cbs-nix-hotfix-task14750.zip) if they exist locally. Copying Dockerfile here
# is just a harmless placeholder file in case the former files does not exist.
COPY Dockerfile cbs-nix*.tar.gz cbs-nix*.zip ./
RUN rm Dockerfile

# Set owner and group to 'ahsay'
RUN chown -R ahsay:ahsay "${APP_HOME}" "/bootstrap" "${DEFAULT_FILES}"

# De-escalate from root
USER ahsay

# Download cbs-nix.tar.gz if not found locally
RUN test -f cbs-nix.tar.gz || curl -fsSL -o cbs-nix.tar.gz "${INSTALLER}"

# Extact and remove cbs-nix.tag.gz
RUN tar \
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
  -xzf cbs-nix.tar.gz && \
  rm cbs-nix.tar.gz

# Download specified hotfixes if they dont already exist on disk
RUN for url in ${HOTFIXES}; do \
    curl -sSLO -C - "${url}"; \
  done

# Extract and remove any hotfixes
#RUN find . -maxdepth 1 -name "cbs-nix*.tar.gz" -exec bash -c 'tar -xzf {} && rm {}' \;
RUN find . -maxdepth 1 -name "cbs-nix*.zip" -exec bash -c 'unzip -oq {} && rm {}' \;

# Hotfixes may create a java folder which would prevent a critical symbolic 
# link from being made later on.
RUN if [[ -d java ]]; then \
    cp -rf java/* java-linux-x64/ \
    && cp -rf java/* java-linux-x86/ \
    && rm -rf java ; \
  fi

# Add SSLv2Hello (allow clients below v6.21.2.0 to connect)
RUN sed -i "conf/server.xml" \
    -e 's|protocols="TLSv1+TLSv1.1+TLSv1.2"|protocols="SSLv2Hello+TLSv1+TLSv1.1+TLSv1.2"|'

# Move 'conf' and 'download' files aside for no-clobber copy during docker-entrypoint.sh
RUN mv "./conf/"* "${DEFAULT_FILES}/conf" \
  && mv "./download/"* "${DEFAULT_FILES}/download"


# CREATE FINAL IMAGE
FROM common
EXPOSE 80 443
COPY --from=builder "/$APP_HOME" "/$APP_HOME"
COPY --from=builder bootstrap/ /bootstrap

# Set owner of root directory to ahsay 
# Permit tomcat to listen on ports < 1024
RUN chown ahsay:ahsay "${APP_HOME}" \
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
