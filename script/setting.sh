#! /usr/bin/env bash

PKGNAME=tjyMOD
VERSION=0.44

# I hope to put site my KANG, kernel and ROM.
giturl="git://github.com/ac1965/tjyMOD.git"
default_url="http://tjy.sakura.ne.jp/pu/up/android"
default_kernel="update_2.6.35-BFS-WIP-AUFS_201111071812.zip" # LorDmodUE-8.3-CFS-b1-aufs
default_baserom="update-cm-7.1.0-DesireHD-KANG_201111050214.signed.zip"
default_gapps="gapps-gb-20110930-237-signed.zip"

base_list="
http://tjy.sakura.ne.jp/pu/up/android/CMWallpapers.apk
http://tjy.sakura.ne.jp/pu/up/android/LatinIME.apk
http://tjy.sakura.ne.jp/pu/up/android/Vending.apk
http://tjy.sakura.ne.jp/pu/up/android/com.gau.go.launcherex.apk
http://tjy.sakura.ne.jp/pu/up/android/com.gau.go.launcherex.theme.gowidget.transparency.apk
"

extra_list="
http://tjy.sakura.ne.jp/pu/up/android/CallRecorder_v.1.0.27_alpha_build05.apk
http://tjy.sakura.ne.jp/pu/up/android/Google++2.0.0.apk
http://tjy.sakura.ne.jp/pu/up/android/Google+Music+4.0.1.apk
http://tjy.sakura.ne.jp/pu/up/android/Google_Maps_v5.11.0.apk
http://tjy.sakura.ne.jp/pu/up/android/com.adobe.reader.apk
http://tjy.sakura.ne.jp/pu/up/android/com.antivirus.apk
http://tjy.sakura.ne.jp/pu/up/android/com.bumptech.bumpga.apk
http://tjy.sakura.ne.jp/pu/up/android/com.calcbuddy.apk
http://tjy.sakura.ne.jp/pu/up/android/com.dropbox.android.apk
http://tjy.sakura.ne.jp/pu/up/android/com.evernote.apk
http://tjy.sakura.ne.jp/pu/up/android/com.google.android.apps.reader.apk
http://tjy.sakura.ne.jp/pu/up/android/com.google.android.apps.translate.apk
http://tjy.sakura.ne.jp/pu/up/android/com.google.android.apps.unveil.apk
http://tjy.sakura.ne.jp/pu/up/android/com.google.android.gm.apk
http://tjy.sakura.ne.jp/pu/up/android/com.google.android.street.apk
http://tjy.sakura.ne.jp/pu/up/android/com.google.android.youtube.apk
http://tjy.sakura.ne.jp/pu/up/android/com.google.zxing.client.android.apk
http://tjy.sakura.ne.jp/pu/up/android/com.jbapps.contactpro.apk
http://tjy.sakura.ne.jp/pu/up/android/com.keramidas.TitaniumBackup.apk
http://tjy.sakura.ne.jp/pu/up/android/com.minus.android.apk
http://tjy.sakura.ne.jp/pu/up/android/com.quoord.tapatalkpro.activity.apk
http://tjy.sakura.ne.jp/pu/up/android/com.xtralogic.android.logcollector.apk
http://tjy.sakura.ne.jp/pu/up/android/dev.sci.systune.apk
http://tjy.sakura.ne.jp/pu/up/android/ext.recovery.control.apk
"

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

