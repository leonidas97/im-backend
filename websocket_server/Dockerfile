FROM erlang:23.0-alpine
COPY . .
RUN rebar3 as prod release

FROM alpine
RUN apk add --no-cache bash
RUN mkdir /app
COPY --from=0 . /app

EXPOSE 8080
