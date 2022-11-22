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

## @fn replace_line_in_file()
## @brief given a regular expression for a line, replace it with a new line
## @details
## This is largely modeled after `line_in_file` from Ansible.  One provides
## a test (a regular expression) and a line.  For lines that match the test
## pattern, replace them with the content line.  Typically the content line
## would match the pattern so that once the replacement is performed, any
## subsequent attempts wouldn't result in changing the file, adding the
## line multiple times, etc..
##
## At its core, replace_line_in_file() uses GNU sed's extended regular
## expressions (`-E`).  Therefore, if one needs to provide an alternative
## executable (e.g., if running on BSD and one needs to use `gsed` instead
## of the system's `sed` command), the `sed_command` environment variable
## may be used to specify the alternate command.
##
## The values in the test and content lines have forward slashes escaped
## such that '/' becomes '\/'.  Therefore, it' unnecessary to perform the
## escaping manually.
##
## If there was no match for the test line, the content line will be
## appended to the end of the file.  If the file did not exist when
## called, it will be created as an empty file (i.e., via `touch`).
## @param filename the name of the file to edit
## @param test_line the regular expression to replace
## @param content_line the line used to replace test_line matches
## @retval 0 (True) if the replacement was successful
## @retval 1 (False) if something failed
## @par Examples
## @code
## replace_line_in_file \
##   "/etc/ssh/sshd_config" \
##   "^[[:space:]#][Pp][Oo][Rr][Tt][[:space:]]+" \
##   "Port 2222"
## @endcode
replace_line_in_file() {

  filename="${1?No file provided}"
  shift

  test_line="$(echo "${1?No test provided}" | sed -Ee 's|/|\\/|g')"
  shift

  content_line="$(echo "${1?No content line provided}" | sed -Ee 's|/|\\/|g')"
  shift

  sed_command="${sed_command:-sed}"

  if [ ! -f "${filename}" ] ; then
    touch "${filename}"
  fi

  "${sed_command}" -i~ -Ee "/^${test_line}/{h;s/${test_line}/${content_line}/};\${x;/^$/{s//${content_line}/;H};x}" "${filename}"

}


# Setup SSH host keys (if needed)


if [ ! -d "${sshd_host_key_directory}" ] ; then
  mkdir -p "${sshd_host_key_directory}"
fi

if [ ! -f "${sshd_host_key_directory}ssh_host_rsa_key" ] ; then
  ssh-keygen -b 4096 -f "${sshd_host_key_directory}ssh_host_rsa_key" -t rsa -N ""
  chown root:root "${sshd_host_key_directory}ssh_host_rsa_key"
  chmod 600 "${sshd_host_key_directory}ssh_host_rsa_key"
fi

if [ ! -f "${sshd_host_key_directory}ssh_host_dsa_key" ] ; then
  ssh-keygen -b 1024 -f "${sshd_host_key_directory}ssh_host_dsa_key" -t dsa -N ""
  chown root:root "${sshd_host_key_directory}ssh_host_dsa_key"
  chmod 600 "${sshd_host_key_directory}ssh_host_dsa_key"
fi

if [ ! -f "${sshd_host_key_directory}ssh_host_ecdsa_key" ] ; then
  ssh-keygen -b 521 -f "${sshd_host_key_directory}ssh_host_ecdsa_key" -t ecdsa -N ""
  chown root:root "${sshd_host_key_directory}ssh_host_ecdsa_key"
  chmod 600 "${sshd_host_key_directory}ssh_host_ecdsa_key"
fi

if [ ! -f "${sshd_host_key_directory}ssh_host_ed25519_key" ] ; then
  ssh-keygen -b 4096 -f "${sshd_host_key_directory}ssh_host_ed25519_key" -t ed25519 -N ""
  chown root:root "${sshd_host_key_directory}ssh_host_ed25519_key"
  chmod 600 "${sshd_host_key_directory}ssh_host_ed25519_key"
fi


# Configure Google Authenticator libpam library


replace_line_in_file \
  "${pam_config_file}" \
  '^[[:space:]#]*auth\b.*pam_google_authenticator\.so.*' \
  "auth ${pam_control} pam_google_authenticator.so ${pam_nullok}"

replace_line_in_file \
  "${pam_config_file}" \
  '^[[:space:]#]*auth\b.*\bpam_permit\.so.*' \
  "auth ${pam_control} pam_permit.so"


# specify host keys


replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*HostKey.*ssh_host_rsa_key' \
  "HostKey ${sshd_host_key_directory}ssh_host_rsa_key"

replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*HostKey.*ssh_host_dsa_key' \
  "HostKey ${sshd_host_key_directory}ssh_host_dsa_key"

replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*HostKey.*ssh_host_ecdsa_key' \
  "HostKey ${sshd_host_key_directory}ssh_host_ecdsa_key"

replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*HostKey.*ssh_host_ed25519_key' \
  "HostKey ${sshd_host_key_directory}ssh_host_ed25519_key"


# Configure sshd


replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*PasswordAuthentication.*' \
  "PasswordAuthentication ${password_authentication}"

replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*PermitRootLogin.*' \
  "PermitRootLogin ${permit_root_login}"

replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*Port.*' \
  "Port ${port}"

replace_line_in_file \
  "${config_file}" \
  '^[[:space:]#]*ClientAliveInterval.*' \
  "ClientAliveInterval ${timeout}"

if [ -n "${allow_users}" ] ; then
  replace_line_in_file \
    "${config_file}" \
    '^[[:space:]#]*AllowUsers.*' \
    "AllowUsers ${allow_users}"
fi


# make sure SSH's privilege separation directory exists


if [ ! -d "${sshd_privsep_directory}" ] ; then
  mkdir -p "${sshd_privsep_directory}"
fi


# run sshd with whatever options are set to us (e.g., -De or -t)
"${sshd_executable}" -e "$@"
