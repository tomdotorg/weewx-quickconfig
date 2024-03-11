#-----------------------------------------------------------
# this does a quick report of basic os and weewx installations
# to aid in debugging.  See the README file for usage
#
# tested on debian, ubuntu, almalinux, freebsd
# and in vagrant as well on those os
#
# this will not work on macos or alpinelinux because
# they are just different for the sake of being different
#-----------------------------------------------------------

DPKG_PRESENT=`which dpkg 2>/dev/null`
YUM_PRESENT=`which yum 2>/dev/null`
ARCH_PRESENT=`which arch 2>/dev/null`
RPM_PRESENT=`which rpm 2>/dev/null`
UNAME=`uname`

# we supersede this on debian systems because on pi it reports
#       incorrectly yet dpkg knows what is really running
if [ "x${ARCH_PRESENT}" != "x" ]
then
  ARCH=`arch`
else
   ARCH=`uname -p`       # freebsd
fi

# we will assume os-release is present rather than
# rely on lsb_release which we know is not always present
if [ -f /etc/os-release ]
then
  source /etc/os-release
fi

if [ "x${DPKG_PRESENT}" != "x" ]
then
  # debian systems

  # supersede the 'arch' command because on a pi it reports
  # the wrong thing, but dpkg knows reality
  ARCH=`dpkg --print-architecture`

  VERSION=`cat /etc/debian_version`

  INSTALLED_WEEWX_PKG=`dpkg -l | grep weewx | awk '{print $3}'`
  if [ "x${INSTALLED_WEEWX_PKG}" = "x" ]
  then
    INSTALLED_WEEWX_PKG="no_pkg_installed"
  fi

elif [ "x${RPM_PRESENT}" != "x" ]
then
  # redhat systems
  INSTALLED_WEEWX_PKG=`rpm -q weewx`
  if [ "x${INSTALLED_WEEWX_PKG}" = "x" ]
  then
    INSTALLED_WEEWX_PKG="no_pkg_installed"
  fi
else
    INSTALLED_WEEWX_PKG="not_available_for_this_os"
fi

#-----------------------------------------
# look for weewx in a few likely places
#-----------------------------------------

# v4 pip
if [ -d /home/weewx ]
then
  HOME_WEEWX_EXISTS="true"
else
  HOME_WEEWX_EXISTS="false"
fi

# pkg
if [ -d /etc/weewx ]
then
  ETC_WEEWX_EXISTS="true"
else
  ETC_WEEWX_EXISTS="false"
fi

# v5 pip pi or vagrant users
if [ -d /home/pi/weewx-venv ]
then
  HOME_VENV_EXISTS="true"
  FOUNDUSER="pi"
elif [ -d /home/vagrant/weewx-venv ]
then
  HOME_VENV_EXISTS="true"
  FOUNDUSER="vagrant"
else
  HOME_VENV_EXISTS="false"
fi

# TODO: this could even output JSON if needed
# TODO: this could even output JSON if needed
# TODO: this could even output JSON if needed
# TODO: this could even output JSON if needed

echo ""
echo "basic system configuration:"
echo "     os        = ${PRETTY_NAME}"
echo "     arch      = ${ARCH}"
echo ""
echo "looking for weewx installations"
echo "     /home/weewx:         ${HOME_WEEWX_EXISTS}"
echo "     /etc/weewx:          ${ETC_WEEWX_EXISTS}"
echo "     /home/${FOUNDUSER}/weewx-venv: ${HOME_VENV_EXISTS}"
echo ""
echo "installed weewx package:"
echo "     weewx_pkg = ${INSTALLED_WEEWX_PKG}"
echo ""

# this attempts to grab the version from the code
# this is a little ugly since there might be multiple python installations
# and varying weewx versions therein, so do some ugly output for those cases
if [ ${HOME_VENV_EXISTS} ]
then
  echo "installed weewx pip version:"

  WEEWX_INIT_FILES=`find /home/${FOUNDUSER}/weewx-venv/lib/python*/site-packages/weewx/__init__.py -type f -print 2>/dev/null`
  WEEWX_INIT_FILES_COUNT=`find /home/${FOUNDUSER}/weewx-venv/lib/python*/site-packages/weewx/__init__.py -type f -print 2>/dev/null | wc -l`
  if [ "x${WEEWX_INIT_FILES_COUNT}" = "x0" ]
  then
    echo "     version   = (none installed)"
  elif [ "x${WEEWX_INIT_FILES_COUNT}" != "x1" ]
  then
   for f in ${WEEWX_INIT_FILES}
   do
    echo "     in file ${f}"
    v=`grep ^__version__ ${f} | awk '{print $3}' | sed -e s/\"//g`
    echo "             ${v}"
  done
  else
  for f in ${WEEWX_INIT_FILES}
  do
    # the typical one-python-version-installed is much cleaner
    v=`grep ^__version__ ${f} | awk '{print $3}' | sed -e s/\"//g`
    echo "     version   = ${v}"
  done
fi
else
  HOME_PI_VENV_EXISTS="false"
fi

#-----------------------------------------

# ok on linux, not on freebsd

if [ "${UNAME}" = "FreeBSD" ]
then
  # hopefully more portable
  RUNNING_WEEWX_PROCESSES=`ps axu | grep weewxd | grep -v grep | awk '{print $11" "$12" "$13" "$14" "$15}'`
else
  RUNNING_WEEWX_PROCESSES=`ps -eo command | grep weewxd | grep -v grep`
fi

if [ "x${RUNNING_WEEWX_PROCESSES}" = "x" ]
then
  RUNNING_WEEWX_PROCESSES="     none"
fi

echo ""
echo "running weewx processes:"
echo "${RUNNING_WEEWX_PROCESSES}"
echo ""

