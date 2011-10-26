#! /usr/bin/env bash

PKGNAME=tjyMOD
VERSION=0.33

# I hope to put site my KANG, kernel and ROM.
giturl="git://github.com/ac1965/tjyMOD.git"
default_url="http://tjy.sakura.ne.jp/pu/up/android"
default_kernel="update_2.6.35-BFS-WIP-AUFS_201110241151.zip"
default_baserom="update-cm-7.1.0-DesireHD-KANG_201110221353.signed.zip"
default_gapps="gapps-gb-20110930-237-signed.zip"

base_list="http://tjy.sakura.ne.jp/pu/up/android/base.list"
extra_list="http://tjy.sakura.ne.jp/pu/up/android/extra.list"

DIRS="system data setup kernel META-INF"
BASEROM_DIRS="system data META-INF"
KERNEL_DIRS="system data kernel"
GAPPS_DIRS="system data"
CLEAN_LIST="kernel \
            system/app/Provision.apk \
            system/app/ADWLauncher.apk \
            system/app/MarketUpgrader.apk \
            setup/kor" # for the moment

O="$workdir/../out"
DOWN_DIR="$workdir/../download"
ART_DIR="$workdir/../artwork"
TEMP_DIR="$workdir/../tmp"
OUT_DIR="${O}/${PKGNAME}_$dt"
BASE_DIR="$workdir/../base"
EXTR_DIR="$workdir/../extra"
TOOLS_DIR="$workdir/../tools"
SDCARD_DIR="${EXTR_DIR}/sdcard"
SDMOD_DIR="${SDCARD_DIR}/tjyMOD"
GPS_DIR="${SDMOD_DIR}/gpsconf"
RIL_DIR="${SDMOD_DIR}/ril"

# color escape
NORMAL="\033[0m"
FIRST_COLOR="\033[1;30m"
DIE_2ND_COLOR="\033[0;36m"
DIE_3RT_COLOR="\033[0;31m"
REMARK_COLOR="\033[1;31m"
INFO_2ND_COLOR="\033[0;36m"
INFO_3RD_COLOR="\033[1;36m"
WARN_2ND_COLOR="\033[0;33m"
WARN_3RD_COLOR="\033[1;33m"
