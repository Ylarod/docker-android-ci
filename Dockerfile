FROM ubuntu:20.04

MAINTAINER Ylarod "me@ylarod.cn"

LABEL "com.github.actions.name"="Android CI Action"
LABEL "com.github.actions.description"="GitHub Actions for Android build with llvm based obfuscator"
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="green"

LABEL "repository"="https://github.com/Ylarod/docker-android-ci"
LABEL "homepage"="https://github.com/Ylarod/docker-android-ci"
LABEL "maintainer"="Ylarod"

ENV ANDROID_HOME=/opt/sdk \
    ANDROID_SDK=/opt/sdk \
    ANDROID_NDK=/opt/ndk \
    ANDROID_NDK_HOME=/opt/ndk \
    GRADLE_USER_HOME=/opt/cache/gradle

# Required for Jenv
SHELL ["/bin/bash", "-c"]

## Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

## Use unicode
RUN apt-get update && apt-get -y install locales && \
    locale-gen en_US.UTF-8 || true
ENV LANG=en_US.UTF-8

## Install dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
  openjdk-11-jdk \
  openjdk-8-jdk \
  git \
  wget \
  build-essential \
  zlib1g-dev \
  libssl-dev \
  libreadline-dev \
  unzip \
  ssh \
  # Fastlane plugins dependencies
  # - fastlane-plugin-badge (curb)
  libcurl4 libcurl4-openssl-dev

## Clean dependencies
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

## Install jenv
ENV JENV_ROOT "$HOME/.jenv"
RUN git clone https://github.com/jenv/jenv.git $JENV_ROOT
ENV PATH "$PATH:$JENV_ROOT/bin"
RUN mkdir $JENV_ROOT/versions
ENV JDK_ROOT "/usr/lib/jvm/"
RUN jenv add ${JDK_ROOT}/java-8-openjdk-amd64
RUN jenv add ${JDK_ROOT}/java-11-openjdk-amd64
RUN echo 'export PATH="$JENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(jenv init -)"' >> ~/.bashrc

## Install Android SDK
ARG sdk_version=commandlinetools-linux-7302050_latest.zip
ARG android_home=/opt/sdk
ARG android_api=android-29
ARG android_build_tools=29.0.3
ARG ndk_version=21.0.6113669
ARG cmake=3.10.2.4988404
RUN mkdir -p ${android_home} && \
    wget --quiet --output-document=/tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
    unzip -q /tmp/${sdk_version} -d ${android_home} && \
    rm /tmp/${sdk_version}

# Set environmental variables
ENV ANDROID_HOME ${android_home}
ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}
RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg
RUN env
RUN yes | /opt/sdk/tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses
RUN /opt/sdk/tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --install \
  "platform-tools" \
  "build-tools;${android_build_tools}" \
  "platforms;${android_api}"

# Install ndk 21.4.7075529-goron
RUN wget https://github.com/Ylarod/goron/releases/download/v1.0/21.4.7075529.tar.gz
RUN tar -xzvf https://github.com/Ylarod/goron/releases/download/v1.0/21.4.7075529.tar.gz -C /opt/
RUN mv /opt/21.4.7075529 /opt/ndk

