FROM node:alpine as builder

COPY .bowerrc   /app/
COPY bower.json /app/

WORKDIR /app

RUN set -ex \
 && apk add \
      git \
 && npm install -g bower \
 && bower --allow-root install \
 && ls -lha vendor/assets

FROM ruby:2.3
MAINTAINER BinaryBabel OSS

RUN set -ex \
 && apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      nodejs \
 && rm -rf /var/lib/apt/lists/*

VOLUME ["/app/data"]

EXPOSE 3333/tcp

ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=1

WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN set -ex \
 && bundle install --deployment --without development test

COPY . /app

COPY --from=builder /app/vendor/assets/bower_components /app/vendor/assets/bower_components

RUN set -ex \
 && ls -lh vendor/assets \
 && ./bin/rake assets:precompile

ENV REFRESH_ENABLED=1

ENTRYPOINT ["./bin/rake"]
CMD ["start"]
