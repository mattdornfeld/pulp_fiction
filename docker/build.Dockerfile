FROM swift:5.6.2-focal

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get -y install npm
RUN apt-get -y install openjdk-17-jdk
RUN npm install -g @bazel/bazelisk
