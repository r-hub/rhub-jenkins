
## Dockerized Jenkins for R-Hub

[R-hub](https://github.com/r-hub) uses this image in the
[dokku-jenkins](https://github.com/r-hub/dokku-jenkins) plugin.

Configuration happens when Jenkins starts, from the passed
encironment variables:
* `JENKINS_ADMIN_USER` Name of the admin user to create.
* `JENKINS_ADMIN_PASSWORD`: Password of this user.
* `JENKINS_PLUGINS` The names of the Jenkins plugins to install.

## License

A significant part of the install script is modified from
https://github.com/blacklabelops/jenkins

MIT @ Steffen Bleul, R Consortium
