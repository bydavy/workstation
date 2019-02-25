# install 1password
FROM ubuntu:18.10 as onepassword_builder
RUN apt-get update && apt-get install -y curl ca-certificates unzip
RUN curl -sS -o 1password.zip https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_linux_amd64_v0.5.5.zip && unzip 1password.zip op -d /usr/bin &&  rm 1password.zip

# base OS
FROM ubuntu:18.10
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get upgrade -y && apt-get install -qq -y \
        build-essential \
        ca-certificates \
        curl \
        docker.io \
        git \
        htop \
        locales \
        man \
        mosh \
        openssh-server \
        python \
        python3 \
        qemu-kvm \
        socat \
        sudo \
        tmux \
        unzip \
        wget \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir /run/sshd
RUN sed -i 's/#Port 22/Port 6001/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
	locale-gen --purge $LANG && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=$LANG LC_ALL=$LC_ALL LANGUAGE=$LANGUAGE

# for correct colours is tmux
ENV TERM screen-256color

# 1Password
COPY --from=onepassword_builder /usr/bin/op /usr/local/bin/

ARG GITHUB_USER=bydavy
RUN mkdir ~/.ssh && curl -fsL https://github.com/$GITHUB_USER.keys > ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

EXPOSE 6001 60000:60010/udp

WORKDIR /root
COPY entrypoint.sh /bin/entrypoint.sh
CMD ["/bin/entrypoint.sh"]