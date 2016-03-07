
## Dockerized Jenkins for R-Hub

[R-hub](https://github.com/r-hub) uses this image in the
[dokku-jenkins](https://github.com/r-hub/dokku-jenkins) plugin.

Configuration happens when Jenkins starts, from the passed
environment variables:
* `JENKINS_ADMIN_USER` Name of the admin user to create.
* `JENKINS_ADMIN_PASSWORD`: Password of this user.
* `JENKINS_PLUGINS` The names of the Jenkins plugins to install.
* `JENKINS_ADMIN_EMAIL` Email address of the Jenkins admin.
  Notification emails are going out from this address.

Environment variables for SMTP:
* `JENKINS_SMTP_HOST` SMTP host, defaults to `localhost`.
* `JENKINS_SMTP_PORT` SMTP port, defaults to 25.
* `JENKINS_SMTP_USER_NAME` SMTP username, if not set, no SMTP
  authentication is used.
* `JENKINS_SMTP_USER_PASS` SMTP password, if not set, no SMTP
  authentication is used.
* `JENKINS_SMTP_REPLYTO_ADDRESS` Defaults to to `<donotreply@>`
* `JENKINS_SMTP_USE_SSL` Defaults to `false`, not using SSL.
* `JENKINS_SMTP_CHARSET` Defautls to UTF-8.

## License

A significant part of the install script is modified from
https://github.com/blacklabelops/jenkins

MIT @ Steffen Bleul, R Consortium
