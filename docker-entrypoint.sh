#!/bin/bash

# This is mostly after https://github.com/blacklabelops/jenkins
# Thanks much!

set -e

# -----------------------------------------------------------------------
# Activate security and add admin user

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

# -----------------------------------------------------------------------
# Install plugins

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

# -----------------------------------------------------------------------
# Set up SMTP, so that Jenkins can send email

if [ ! -d "${JENKINS_HOME}/init.groovy.d" ]; then
    mkdir ${JENKINS_HOME}/init.groovy.d
fi

cat > ${JENKINS_HOME}/init.groovy.d/initSMTP.groovy <<_EOF_
  import jenkins.model.*
  def inst = Jenkins.getInstance()
  def desc = inst.getDescriptor("hudson.tasks.Mailer")
  desc.setReplyToAddress("${JENKINS_SMTP_REPLYTO_ADDRESS:-<donotreply@>}")
  desc.setSmtpHost("${JENKINS_SMTP_HOST:-localhost}")
  desc.setUseSsl(${JENKINS_SMTP_USE_SSL:-false})
  desc.setSmtpPort("${JENKINS_SMTP_PORT:-25}")
  desc.setCharset("${JENKINS_SMTP_CHARSET:-UTF-8}")
_EOF_

# No auth needed by default, the mail server should only accept
# mail from localhost if authentication is not set.
if [ -n "${JENKINS_SMTP_USER_NAME}" ] &&
   [ -n "${JENKINS_SMTP_USER_PASS}" ]; then
    cat >> ${JENKINS_HOME}/init.groovy.d/initSMTP.groovy <<_EOF_
  desc.setSmtpAuth("${JENKINS_SMTP_USER_NAME}", "${JENKINS_SMTP_USER_PASS}")
_EOF_
fi

cat >> ${JENKINS_HOME}/init.groovy.d/initSMTP.groovy <<_EOF_
  desc.save()
  inst.save()
_EOF_

# -----------------------------------------------------------------------
# Email address for the admin. Emails are going out with this
# email address, so it is good to set it.

if [ -n "${JENKINS_ADMIN_EMAIL}" ]; then
    if [ ! -d "${JENKINS_HOME}/init.groovy.d" ]; then
	mkdir ${JENKINS_HOME}/init.groovy.d
    fi
    cat > ${JENKINS_HOME}/init.groovy.d/initAdminEMail.groovy <<_EOF_
  import jenkins.model.*
  import java.util.logging.Logger
  def instance = Jenkins.getInstance()
  def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()
  jenkinsLocationConfiguration.setAdminAddress("${JENKINS_ADMIN_EMAIL}")
  jenkinsLocationConfiguration.save()
  instance.save()
_EOF_
fi

# -----------------------------------------------------------------------
# Set some environment variables.
#
# PS4 is used by bash debugging, we make sure that we can reliably mark
# the debug lines, so they can be filtered out from the output sent to the
# users

cat > ${JENKINS_HOME}/init.groovy.d/setEnvVars.groovy <<_EOF_

  import jenkins.model.*
  def instance = Jenkins.getInstance()
  def globalNodeProperties = instance.getGlobalNodeProperties()
  def envVarsNodePropertyList = globalNodeProperties.getAll(hudson.slaves.EnvironmentVariablesNodeProperty.class)

  def newEnvVarsNodeProperty = null
  def envVars = null

  if (envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0) {
    newEnvVarsNodeProperty = new hudson.slaves.EnvironmentVariablesNodeProperty();
    globalNodeProperties.add(newEnvVarsNodeProperty)
    envVars = newEnvVarsNodeProperty.getEnvVars()
  } else {
    envVars = envVarsNodePropertyList.get(0).getEnvVars()
  }

  envVars.put("PS4", "+R-HUB-R-HUB-R-HUB")
  envVars.put("JAVA_OPTS", "-Dfile.encoding=UTF-8")

  instance.save()
_EOF_

# -----------------------------------------------------------------------

unset JENKINS_ADMIN_USER
unset JENKINS_ADMIN_PASSWORD
unset JENKINS_SMTP_USER_NAME
unset JENKINS_SMTP_USER_PASS

# -----------------------------------------------------------------------

exec /usr/local/bin/jenkins.sh
