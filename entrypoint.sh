#!/usr/bin/env bash

set -euo pipefail

config_file="${config_file:-/etc/ssh/sshd_config}"

password_authentication="${password_authentication:-no}"
permit_root_login="${permit_root_login:-no}"
port="${port:-22}"
timeout="${timeout:-300}"
allow_users="${allow_users:-}"
pam_config_file="${pam_config:-/etc/pam.d/common-auth}"
pam_control="${pam_control:-required}"
pam_nullok="${pam_nullok:-nullok}"

sshd_host_key_directory="${sshd_host_key_directory:-/etc/ssl/private/sshd/}"
sshd_privsep_directory="${sshd_privsep_directory:-/run/sshd}"
sshd_executable="${sshd_executable:-/usr/sbin/sshd}"

line_in_file() {
  filename="${1?No file provided}"
  shift

  test_line="${1?No test provided}"
  shift

  content_line="${1?No content line provided}"
  shift

  if grep -qiEe "${test_line}" "${config_file}" ; then
    sed -i~ -Ee "s|${test_line}|${content_line}|I" "${filename}"
  else
    echo "${content_line}" >> "${filename}"
  fi
}

if [ ! -d "${sshd_host_key_directory}" ] ; then
  mkdir -p "${sshd_host_key_directory}"
fi

if [ ! -f "${sshd_host_key_directory}ssh_host_rsa_key" ] ; then
  ssh-keygen -b 4096 -f "${sshd_host_key_directory}ssh_host_rsa_key" -t rsa -N ""
fi

if [ ! -f "${sshd_host_key_directory}ssh_host_dsa_key" ] ; then
  ssh-keygen -b 1024 -f "${sshd_host_key_directory}ssh_host_dsa_key" -t dsa -N ""
fi


if [ ! -f "${sshd_host_key_directory}ssh_host_ecdsa_key" ] ; then
  ssh-keygen -b 521 -f "${sshd_host_key_directory}ssh_host_ecdsa_key" -t ecdsa -N ""
fi

if [ ! -f "${sshd_host_key_directory}ssh_host_ed25519_key" ] ; then
  ssh-keygen -b 4096 -f "${sshd_host_key_directory}ssh_host_ed25519_key" -t ed25519 -N ""
fi

chmod 600 ${sshd_host_key_directory}ssh_host*

line_in_file \
  "${pam_config_file}" \
  '^\s*#?\s*auth\b.*\bpam_google_authenticator\.so.*' \
  "auth ${pam_control} pam_google_authenticator.so ${pam_nullok}"

line_in_file \
  "${pam_config_file}" \
  '^\s*#?\s*auth\b.*\bpam_permit\.so.*' \
  "auth ${pam_control} pam_permit.so"

line_in_file \
  "${config_file}" \
  '^\s*#\s*HostKey.*ssh_host_rsa_key' \
  "HostKey ${sshd_host_key_directory}ssh_host_rsa_key"

line_in_file \
  "${config_file}" \
  '^\s*#\s*HostKey.*ssh_host_ecdsa_key' \
  "HostKey ${sshd_host_key_directory}ssh_host_ecdsa_key"

line_in_file \
  "${config_file}" \
  '^\s*#\s*HostKey.*ssh_host_ed25519_key' \
  "HostKey ${sshd_host_key_directory}ssh_host_ed25519_key"

line_in_file \
  "${config_file}" \
  '^\s*#?\s*PasswordAuthentication.*' \
  "PasswordAuthentication ${password_authentication}"

line_in_file \
  "${config_file}" \
  '^\s*#?\s*PermitRootLogin.*' \
  "PermitRootLogin ${permit_root_login}"

line_in_file \
  "${config_file}" \
  '^\s*#?\s*Port.*' \
  "Port ${port}"

line_in_file \
  "${config_file}" \
  '^\s*#?\s*ClientAliveInterval.*' \
  "ClientAliveInterval ${timeout}"

if [ -n "${allow_users}" ] ; then
  line_in_file \
    "${config_file}" \
    '^\s*#?\s*AllowUsers.*' \
    "AllowUsers ${allow_users}"
fi

if [ ! -d "${sshd_privsep_directory}" ] ; then
  mkdir -p "${sshd_privsep_directory}"
fi

cat "${config_file}"
"${sshd_executable}" -e "$@"
