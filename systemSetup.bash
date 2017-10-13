#!/bin/bash
# shellcheck disable=SC2154
###############################################################################
############################# System preparation ##############################
if [ -n "${set_name:?}" ]; then
  echo "Searching for a set named $set_name..."
  my_set=$(FindOnlineSet "$set_name" "$lo_src_repo" "$set_core_regex" "$lool_src_repo" "$set_online_regex" "$set_version")
  if [ -n "$my_set" ]; then
    lo_src_branch=$(echo $my_set | awk '{print $1}') && echo "Core branch: $lo_src_branch"
    lool_src_branch=$(echo $my_set | awk '{print $2}') && echo "Online branch: $lool_src_branch"
  fi
fi
# run apt update && upgrade if last update is older than 1 day
find /var/lib/apt/lists/ -mtime -1 |grep -q partial || apt-get update && apt-get upgrade -y

${sh_interactive} && apt-get install dialog -y

grep -q '# deb-src' ${soli} && sed -i 's/# deb-src/deb-src/g' ${soli} && apt-get update

# Need to checkout Distrib/Release
apt-get install lsb-release -y

DIST=$(lsb_release -si)
# RELEASE=`lsb_release -sr`

DIST_PKGS=""
if [ "${DIST}" = "Ubuntu" ]; then
  DIST_PKGS="${DIST_PKGS} openjdk-8-jdk"
fi
if [ "${DIST}" = "Debian" ]; then
  DIST_PKGS="${DIST_PKGS} openjdk-8-jdk"
fi

if ! apt-get install ant sudo systemd wget zip make procps automake bison ccache \
flex g++ git gperf graphviz junit4 libcap-dev libcppunit-dev \
libcppunit-doc libcunit1 libcunit1-dev libegl1-mesa-dev libfontconfig1-dev libgl1-mesa-dev \
libgtk-3-dev libgtk2.0-dev libkrb5-dev libpcap0.8 libpcap0.8-dev libtool \
libxml2-utils libxrandr-dev libxrender-dev libxslt1-dev libxt-dev m4 nasm openssl \
pkg-config python-dev python-polib python3-dev uuid-runtime xsltproc \
  ${DIST_PKGS} -y; then
    exit 1
fi
if ! ${lo_mini}; then
  apt-get install doxygen libcups2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev -y
fi
apt-get build-dep libreoffice -y

if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
  curl -sL https://deb.nodesource.com/setup_6.x | bash -
  apt-get install nodejs -y
fi
if ${lo_non_free_ttf}; then
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get install ttf-mscorefonts-installer -y
fi

getent passwd lool || (useradd lool -G sudo; mkdir /home/lool)
chown lool:lool /home/lool -R
