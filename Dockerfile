
FROM jenkins

MAINTAINER "r-hub admin" admin@r-hub.io

USER jenkins

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
