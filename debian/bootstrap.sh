#!/bin/bash
##### -*- mode:shell-script; indent-tabs-mode:nil; sh-basic-offset:2 -*-
##### Author: Travis Cross <tc@traviscross.com>

base="freeswitch-sounds"
sound="$(dpkg-parsechangelog | grep '^Source' | awk '{print $2}' | sed -e "s/${base}-//")"
path="$(echo "$sound" | sed -e 's:-:/:g')"
sound_name="US English Callie"
rate="48000"
version="$(dpkg-parsechangelog | grep ^Version | awk '{print $2}' | cut -d'-' -f1)"

#### lib

ddir="."
[ -n "${0%/*}" ] && ddir="${0%/*}"
cd $ddir

err () {
  echo "$0 error: $1" >&2
  exit 1
}

xread () {
  local xIFS="$IFS"
  IFS=''
  read $@
  local ret=$?
  IFS="$xIFS"
  return $ret
}

wrap () {
  local fl=true
  echo "$1" | fold -s -w 69 | while xread l; do
    local v="$(echo "$l" | sed -e 's/ *$//g')"
    if $fl; then
      fl=false
      echo "$v"
    else
      echo " $v"
    fi
  done
}

fmt_edit_warning () {
  echo "#### Do not edit!  This file is auto-generated from debian/bootstrap.sh."; echo
}

#### control

fmt_provides () {
  local pvds="$base" tmp="${sound%-*}" tb="$base"
  for x in ${tmp//-/ }; do
    tb="$tb-$x"
    pvds="$pvds, $tb"
  done
  echo "$pvds"
}

fmt_control () {
  fmt_edit_warning
  cat <<EOF
Source: freeswitch-sounds-$sound
Section: comm
Priority: optional
Maintainer: Travis Cross <tc@traviscross.com>
Build-Depends: debhelper (>= 8.0.0), sox, flac
Standards-Version: 3.9.3
Homepage: http://files.freeswitch.org/

Package: $base-$sound
$(wrap "Provides: $(fmt_provides)")
Architecture: all
Depends: \${misc:Depends}, sox, flac
Description: $sound_name sounds for FreeSWITCH
 $(wrap "This package contains the ${sound_name} sounds for FreeSWITCH.")

EOF
}

gen_control () {
  fmt_control > control
}

#### install

fmt_pkg_install () {
  fmt_edit_warning
  cat <<EOF
/usr/share/freeswitch/sounds/${path}
EOF
}

gen_install () {
  fmt_pkg_install > $base-$sound.install
}

#### overrides

fmt_itp_override () {
  local p="$1"
  cat <<EOF
# We're not in Debian (yet) so we don't have an ITP bug to close.
${p}: new-package-should-close-itp-bug

EOF
}

fmt_long_filename_override () {
  local p="$1"
  cat <<EOF
# The long file names are caused by appending the nightly information.
# Since one of these packages will never end up on a Debian CD, the
# related problems with long file names will never come up here.
${p}: package-has-long-file-name *

EOF
}

fmt_upstream_changelog_override () {
  local p="$1"
  cat <<EOF
# There is no upstream changelog associated with this package.
${p}: no-upstream-changelog

EOF
}

fmt_pkg_overrides () {
  fmt_edit_warning
  fmt_itp_override "$@"
  fmt_long_filename_override "$@"
  fmt_upstream_changelog_override "$@"
}

gen_overrides () {
  for x in "$base-$sound"; do
    fmt_pkg_overrides "$x" > $x.lintian-overrides
  done
}

#### templated files

tmpl () {
  sed \
    -e "s:__RATE__:${rate}:" \
    -e "s:__PKG_NAME__:${base}-${sound}:" \
    -e "s:__PATH__:${path}:" \
    -e "s:__SPATH__:/usr/share/freeswitch/sounds/${path}:" \
    -e "s:__VERSION__:${version}:" \
    "$1.tmpl" > "$1"
}

tmpl_files () {
  for x in postinst prerm rules watch; do
    tmpl $x
  done
  chmod +x rules
}

#### main

gen_control
gen_install
gen_overrides
tmpl_files

