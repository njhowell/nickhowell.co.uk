FROM ubuntu:16.04

RUN apt-get install -y build-essential ruby ruby-dev
RUN gem install jekyll bundler
