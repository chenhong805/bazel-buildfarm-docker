FROM jinhongc/bazel-python:2

ARG PROXY
ENV http_proxy $PROXY
ENV https_proxy $PROXY
ENV HTTP_PROXY $PROXY
ENV HTTPS_PROXY $PROXY

ARG JAVA_KEYSTORE=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts
ENV JAVA_KEYSTORE=${JAVA_KEYSTORE}
ARG JAVA_KEYSTORE_PASSWORD=changeit
ENV JAVA_KEYSTORE_PASSWORD=${JAVA_KEYSTORE_PASSWORD}

ARG BAZEL_VERSION=6.4.0
ENV BAZEL_VERSION=${BAZEL_VERSION}
ENV DEB_FILE=bazel_$BAZEL_VERSION-linux-x86_64.deb

RUN apt-get update
RUN apt-get install --no-install-recommends -y \
  bash-completion \
  ca-certificates \
  openjdk-8-jdk-headless \
  g++ \
  git \
  patch \
  unzip \
  wget \
  zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY proxy-certs/* /usr/local/share/ca-certificates/
RUN update-ca-certificates
RUN for file in $(find /usr/local/share/ca-certificates/ -name *.crt); do keytool -import -noprompt -alias alias3 -keystore ${JAVA_KEYSTORE} -storepass ${JAVA_KEYSTORE_PASSWORD} -file $file; done

RUN wget --no-check-certificate https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${DEB_FILE}
RUN dpkg -i ${DEB_FILE}\
  && rm ${DEB_FILE}

# https://github.com/bazelbuild/bazel/issues/5741#issuecomment-418071387
# --host_jvm_args=-Djavax.net.debug=all
RUN echo "startup --host_jvm_args=-Djavax.net.ssl.trustStore=${JAVA_KEYSTORE} --host_jvm_args=-Djavax.net.ssl.trustStorePassword=${JAVA_KEYSTORE_PASSWORD} --host_jvm_args=-Djava.net.useSystemProxies=true" > ~/.bazelrc

RUN git clone --depth 1 --branch 2.9.0 https://github.com/bazelbuild/bazel-buildfarm /app/bazel-buildfarm
WORKDIR /app/bazel-buildfarm

# need install redis

# RUN apt install -y vim redis-server
# RUN sed -i # to configure bind address at /etc/redis/redis.conf
# RUN redis-server /etc/redis/redis.conf
# RUN /var/log/redis/redis-server.log

#RUN bazel build //src/main/java/build/buildfarm:buildfarm-server
# RUN bazel run //src/main/java/build/buildfarm:buildfarm-server -- --jvm_flag=-Djava.util.logging.config.file=$PWD/examples/logging.properties $PWD/examples/config.minimal.yml
#RUN bazel build //src/main/java/build/buildfarm:buildfarm-shard-worker
# RUN bazel run //src/main/java/build/buildfarm:buildfarm-shard-worker -- --jvm_flag=-Djava.util.logging.config.file=$PWD/examples/logging.properties $PWD/examples/config.minimal.yml

# -- to add redis node: https://github.com/bazelbuild/bazel-buildfarm/tree/2.9.0
# 

#WORKDIR /app
#RUN mv bazel-buildfarm/bazel-bin/src/main/java/build/buildfarm/buildfarm-server* bazel-buildfarm/bazel-bin/src/main/java/build/buildfarm:buildfarm-shard-worker* /app \
#  && rm -rf /app/bazel-buildfarm

#ENTRYPOINT /app/buildfarm-server /config/server.config
