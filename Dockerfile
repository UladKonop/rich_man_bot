FROM ruby:3.2.8

WORKDIR /app

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install

COPY . .
