FROM ruby:latest

ENV HOME="/root"
WORKDIR ${HOME}

# Set up external packages
RUN apt update
RUN apt install -y lsb-release apt-transport-https ca-certificates
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN apt update
RUN apt upgrade -y
# Every command is on a single line because it makes testing easier
# Build dependencies
RUN apt install -y build-essential
RUN apt install -y curl
RUN apt install -y git
# Language tools
RUN apt install -y nodejs
RUN apt install -y npm
RUN apt install -y openjdk-17-jdk
RUN apt install -y php8.2
RUN apt install -y php8.2-mbstring
RUN apt install -y python3

# Install tree-sitter
RUN git clone https://github.com/tree-sitter/tree-sitter
RUN cd tree-sitter && git checkout tags/v0.22.6
RUN make -C tree-sitter
RUN make -C tree-sitter install

# Download language parsers
WORKDIR /tree-sitter-parsers
RUN curl -o libtree-sitter-embedded-template.so -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-embedded-template-$(uname -m)-linux-gnu.so"
RUN curl -o libtree-sitter-html.so              -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-html-$(uname -m)-linux-gnu.so"
RUN curl -o libtree-sitter-javascript.so        -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-javascript-$(uname -m)-linux-gnu.so"
RUN curl -o libtree-sitter-ruby.so              -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-ruby-$(uname -m)-linux-gnu.so"
RUN curl -o libtree-sitter-php.so               -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-php-$(uname -m)-linux-gnu.so"
RUN curl -o libtree-sitter-java.so              -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-java-$(uname -m)-linux-gnu.so"
# RUN curl -o libtree-sitter-json.so              -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-json-$(uname -m)-linux-gnu.so"
RUN curl -o libtree-sitter-python.so            -L "https://github.com/Faveod/tree-sitter-parsers/releases/download/v1.0.2/libtree-sitter-python-$(uname -m)-linux-gnu.so"

# Reduce image size
RUN rm -rf /var/cache/apk/*

WORKDIR ${HOME}
RUN rm -rf tree-sitter
