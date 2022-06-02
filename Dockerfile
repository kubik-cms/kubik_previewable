FROM node
MAINTAINER Bart Oleszczyk <bart@primate.co.uk>
ENV APP_PATH /kubik_media_library
RUN mkdir /kubik_media_library
WORKDIR /kubik_media_library

# YARN
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get -y install yarn
RUN yarn install
