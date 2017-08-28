FROM ruby:2.4.1-alpine

RUN apk add --no-cache \
  alpine-sdk docker

WORKDIR /app

COPY app/Gemfile* ./

RUN bundle install

COPY app .

ENTRYPOINT ["./entrypoint.sh"]
CMD ["web"]
