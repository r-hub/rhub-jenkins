#!/bin/bash

# This is mostly after https://github.com/blacklabelops/jenkins
# Thanks much!

set -e

if [ -n "${JENKINS_ADMIN_USER}" ] && [ -n "${JENKINS_ADMIN_PASSWORD}" ]; then
  mkdir -p ${JENKINS_HOME}/init.groovy.d

  cat > ${JENKINS_HOME}/init.groovy.d/initAdmin.groovy <<_EOF_
import jenkins.model.*
import hudson.security.*
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def users = hudsonRealm.getAllUsers()
if (!users || users.empty) {
  hudsonRealm.createAccount("${JENKINS_ADMIN_USER}", "${JENKINS_ADMIN_PASSWORD}")
  instance.setSecurityRealm(hudsonRealm)
  def strategy = new GlobalMatrixAuthorizationStrategy()
  strategy.add(Jenkins.ADMINISTER, "${JENKINS_ADMIN_USER}")
  instance.setAuthorizationStrategy(strategy)
}
instance.save()
_EOF_
fi

if [ -n "${JENKINS_PLUGINS}" ]; then
  if [ ! -d "${JENKINS_HOME}/init.groovy.d" ]; then
    mkdir ${JENKINS_HOME}/init.groovy.d
  fi
  jenkins_plugins=${JENKINS_PLUGINS}
  cat > ${JENKINS_HOME}/init.groovy.d/loadPlugins.groovy <<_EOF_
  import jenkins.model.*
  import java.util.logging.Logger

  def logger = Logger.getLogger("")
  def installed = false
  def initialized = false

  def pluginParameter="${jenkins_plugins}"
  def plugins = pluginParameter.split()
  logger.info("" + plugins)
  def instance = Jenkins.getInstance()
  def pm = instance.getPluginManager()
  def uc = instance.getUpdateCenter()
  uc.updateAllSites()

  plugins.each {
    logger.info("Checking " + it)
    if (!pm.getPlugin(it)) {
      logger.info("Looking UpdateCenter for " + it)
      if (!initialized) {
        uc.updateAllSites()
        initialized = true
      }
      def plugin = uc.getPlugin(it)
      if (plugin) {
        logger.info("Installing " + it)
        plugin.deploy()
        installed = true
      }
    }
  }

  if (installed) {
    logger.info("Plugins installed, initializing a restart!")
    instance.save()
    instance.doSafeRestart()
  }
_EOF_
fi

unset JENKINS_ADMIN_USER
unset JENKINS_ADMIN_PASSWORD

exec /usr/local/bin/jenkins.sh
