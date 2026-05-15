FROM jenkins/jenkins:lts-alpine-jdk21

USER root

RUN apk add --no-cache docker-cli

USER jenkins

RUN jenkins-plugin-cli --plugins "blueocean docker-workflow gitlab-plugin sonarqube-generic-analyzer"