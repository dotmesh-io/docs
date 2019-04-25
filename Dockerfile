FROM ubuntu:16.04 AS build-env

# versions
ENV HUGO_VERSION=0.33

# install
RUN apt-get update
RUN apt-get install -y curl bzip2
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.deb > hugo.deb
RUN dpkg -i hugo.deb
RUN rm -f hugo.deb
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get install -y nodejs
RUN npm install -g gulp

# app
WORKDIR /app
ADD ./design/package.json /app/design/package.json
ADD ./design/package-lock.json /app/design/package-lock.json
RUN cd design && npm install
ADD . /app

RUN (cd /app/hugo && hugo -v)

FROM nginx:alpine
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY --from=build-env /app/hugo/public /www