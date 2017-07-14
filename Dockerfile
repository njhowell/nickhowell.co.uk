FROM ubuntu:16.04

RUN apt-get update && apt-get install -y build-essential ruby ruby-dev
RUN gem install jekyll bundler

RUN groupadd -g 116 jenkins
RUN useradd jenkins --shell /bin/bash --create-home -u 109 -g 116
USER jenkins
