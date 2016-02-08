
FROM jenkins

MAINTAINER "r-hub admin" admin@r-hub.io

USER jenkins

ENV JENKINS_PLUGINS "swarm"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
