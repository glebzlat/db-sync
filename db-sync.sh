#!/bin/bash

CONFIG_DIR="$HOME/.config/db-sync"
CONFIG_FILE="$CONFIG_DIR/config"

error() {
    echo -e "Error: $@" 1>&2
    exit 1
}

ensure_command() {
    local cmd="$1"
    local out=$(command -v "${cmd}" 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "Command ${cmd} found: ${out}"
    else
        error "${cmd} is not installed"
    fi
}

ensure_var_set() {
    local var="$1"
    [[ -z "${!var}" ]] && error "variable ${var} is not set"
}

fix_permissions() {
    local file="$1"
    local perm=$(stat --format="%a" "${file}")
    if [[ "${perm}" != 700 ]]; then
        chmod 700 "${file}"
    fi
}

ensure_command rclone
ensure_command keepassxc-cli

if [[ "$(id -u)" = 0 ]]; then
    error "the script must be run as user"
fi

if [[ "$(stat --format="%a" "$0")" != "700" ]]; then
    error "script $0 has wrong permissions, aborting"
fi

. "${CONFIG_FILE}"
ensure_var_set local_file
ensure_var_set remote
ensure_var_set remote_dir
ensure_var_set backup_pattern
ensure_var_set password_file
ensure_var_set backup_dir

fix_permissions "${CONFIG_DIR}"
fix_permissions "${CONFIG_FILE}"

password_file="${CONFIG_DIR}/$(basename "${password_file}")"
if [[ ! -f "${password_file}" ]]; then
    error "password file ${password_file} does not exist or not a file"
fi

fix_permissions "${password_file}"

if [[ ! -f "${local_file}" ]]; then
    error "local database file ${local_file} does not exist or not a file"
fi

filename="$(basename "${local_file}")"
local_dir="$(dirname "${local_file}")"
remote_file="${remote}:${remote_dir}/${filename}"

echo "Retrieving info about the remote"
rclone about "${remote}:"

if rclone ls "${remote_file}" 2>&1 >/dev/null; then
    if ! rclone check "${remote_dir}" "${local_dir}" --include "${filename}" \
            --combined 2>&1 | grep -q -E '^='; then
        echo "No differences between remote and local databases, exiting"
        exit 0
    fi

    echo "Backup the local file"
    remote_backup="${remote}:${backup_dir}/$(date "+${backup_pattern}")"
    rclone copyto "${local_file}" "${remote_backup}"
    if [[ "$?" -ne 0 ]]; then
        error "backup failed, do not proceed"
    fi

    tmpdir=$(mktemp -d)
    trap 'rm -rf "${tmpdir}"' ERR EXIT

    local_copy="${tmpdir}/$(basename "${local_file}")"

    echo "Fetch the remote file"
    rclone copyto "${remote_file}" "${local_copy}"

    password=$(cat "${password_file}")

    echo "Merge databases"
    echo "${password}" | keepassxc-cli merge -s "${local_file}" "${local_copy}"
fi

echo "Save the current database"
rclone copyto "${local_file}" "${remote}:${remote_file}"
