FROM registry.access.redhat.com/ubi9/ubi
LABEL org.opencontainers.image.source="https://github.com/quarkusio/spring-quarkus-perf-comparison"

USER root

# Install homebrew requirements
# RUN dnf group install -y 'Development Tools'
#RUN dnf group install -y development-tools

# Install system dependencies
RUN dnf install -y --allowerasing gcc zlib-devel git procps-ng curl file bash unzip zip sudo
#RUN sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Install homebrew
RUN curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

# Add a new non-root user
RUN useradd -r -u 1000 -g wheel -s /bin/bash benchmark

# Allow benchmark user to use sudo without password
RUN echo "benchmark ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER benchmark
WORKDIR /home/benchmark

# Install nvm
RUN touch ~/.bashrc && chmod +x ~/.bashrc
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
RUN . ~/.nvm/nvm.sh && \
    nvm install --lts && \
    nvm use --lts

# Install jbang
RUN curl -Ls https://sh.jbang.dev | bash -s - app setup

# Install sdkman
RUN curl -s "https://get.sdkman.io" | bash && \
    source "$HOME/.sdkman/bin/sdkman-init.sh"

# Configure homebrew
ENV HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew \
		HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar \
		HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew \
		PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}
RUN	echo "eval \$(${HOMEBREW_PREFIX}/bin/brew shellenv)" >> ~/.bashrc

# Keep container running and wait for connections
CMD ["tail", "-f", "/dev/null"]