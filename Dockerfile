FROM ruby:latest

RUN apt-get install -y build-essential ruby ruby-dev
RUN gem install jekyll bundler