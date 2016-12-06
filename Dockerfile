FROM ruby:2.3.1-slim

RUN apt-get update -qq && apt-get install -y build-essential \
  libpq-dev


RUN adduser --disabled-password --gecos '' r

ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
  BUNDLE_JOBS=5 \
  BUNDLE_PATH=/bundle

RUN bundle check || bundle install

COPY . $APP_HOME/
