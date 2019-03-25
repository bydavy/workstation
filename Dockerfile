# install 1password
FROM ubuntu:18.10 as onepassword_builder
RUN apt-get update && apt-get install -y curl ca-certificates unzip
RUN curl -sS -o 1password.zip https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_linux_amd64_v0.5.5.zip && unzip 1password.zip op -d /usr/bin && rm 1password.zip

# Kotlin compiler
# https://github.com/JetBrains/kotlin/releases/latest
FROM ubuntu:18.10 as kotlin_builder
ARG KOTLIN_VERSION=1.3.21
RUN apt-get update && apt-get install -y curl ca-certificates unzip wget
RUN cd /opt && \
    wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip && \
    unzip *kotlin*.zip && \
    rm *kotlin*.zip

# Android SDK
# https://developer.android.com/studio/#downloads
FROM ubuntu:18.10 as android_sdk_builder
ARG ANDROID_SDK_VERSION=4333796
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN apt-get update && apt-get install -y curl ca-certificates unzip wget openjdk-8-jdk
RUN mkdir -p /opt/android-sdk && cd /opt/android-sdk && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip && \
    unzip *tools*linux*.zip && \
    rm *tools*linux*.zip && \
    yes | /opt/android-sdk/tools/bin/sdkmanager --licenses
RUN /opt/android-sdk/tools/bin/sdkmanager --update && \
    /opt/android-sdk/tools/bin/sdkmanager "build-tools;28.0.3" \
                                          "platform-tools" \
                                          "sources;android-28" \
                                          "platforms;android-28" \
                                          "add-ons;addon-google_apis-google-24" \
                                          "extras;google;google_play_services" \
                                          "extras;android;m2repository" \
                                          "extras;google;m2repository" \
                                          "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"

# base OS
FROM ubuntu:18.10
ENV DEBIAN_FRONTEND=noninteractive

# 1Password
COPY --from=onepassword_builder /usr/bin/op /usr/local/bin/
# Kotlin
COPY --from=kotlin_builder /opt/kotlinc /opt/kotlinc
# Android SDK
COPY --from=android_sdk_builder /opt/android-sdk /opt/android-sdk

RUN apt-get update -qq && apt-get upgrade -y && apt-get install -qq -y \
        ansible \
        build-essential \
        ca-certificates \
        curl \
        docker.io \
        fish \
        git \
        htop \
        jq \
        locales \
        man \
        mosh \
        neovim \
        openjdk-8-jdk \
        openssh-server \
        python \
        python3 \
        qemu-kvm \
        socat \
        sudo \
        tmux \
        unzip \
        vifm \
        wget \
        && rm -rf /var/lib/apt/lists/*

# Set fish as default shell
RUN chsh -s /usr/bin/fish

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV KOTLIN_HOME /opt/kotlinc
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${KOTLIN_HOME}/bin:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin

RUN mkdir /run/sshd
RUN sed -i 's/#Port 22/Port 6010/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
	locale-gen --purge $LANG && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=$LANG LC_ALL=$LC_ALL LANGUAGE=$LANGUAGE

# for correct colours in tmux
ENV TERM screen-256color

ARG GITHUB_USER=bydavy
RUN mkdir ~/.ssh && curl -fsL https://github.com/$GITHUB_USER.keys > ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

EXPOSE 6010 60000:60010/udp

WORKDIR /root
COPY entrypoint.sh /bin/entrypoint.sh
CMD ["/bin/entrypoint.sh"]
