#!/usr/bin/env bash

set -euo pipefail

log() {
    printf '[setup-web] %s\n' "$*"
}

fail() {
    printf '[setup-web] Error: %s\n' "$*" >&2
    exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
    fail "Run this script as root (for example: sudo bash setup-web.sh)."
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
composer_json="${script_dir}/composer.json"
[[ -r "${composer_json}" ]] || fail "composer.json not found next to the setup script: ${composer_json}"

if [[ ! -r /etc/os-release ]]; then
    fail "Cannot identify the operating system; this script supports Ubuntu."
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
    fail "This script supports Ubuntu; detected ${PRETTY_NAME:-an unknown operating system}."
fi

is_installed() {
    [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null || true)" == "installed" ]]
}

missing_packages=()

if ! is_installed php-cli || ! command -v php >/dev/null 2>&1; then
    missing_packages+=(php-cli)
fi

if ! is_installed nginx || ! command -v nginx >/dev/null 2>&1; then
    missing_packages+=(nginx)
fi

if ! is_installed composer || ! command -v composer >/dev/null 2>&1; then
    missing_packages+=(composer)
fi

if ! is_installed acl || ! command -v setfacl >/dev/null 2>&1; then
    missing_packages+=(acl)
fi

if ! is_installed libcap2-bin || ! command -v setcap >/dev/null 2>&1; then
    missing_packages+=(libcap2-bin)
fi

apt-get update
if (( ${#missing_packages[@]} > 0 )); then
    log "Installing missing packages: ${missing_packages[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing_packages[@]}"
fi

composer --version

if ! required_php_version="$(php -r '
$manifest = json_decode(file_get_contents($argv[1]), true, 512, JSON_THROW_ON_ERROR);
$requirement = $manifest["require"]["php"] ?? null;
if (!is_string($requirement) || !preg_match("/^>=\\s*v?(\\d+\\.\\d+(?:\\.\\d+)?)$/", trim($requirement), $matches)) {
    fwrite(STDERR, "Expected composer.json to define PHP as a single >= version constraint.\\n");
    exit(1);
}
echo $matches[1];
' "${composer_json}")"; then
    fail "Could not read a supported PHP minimum version from composer.json."
fi

mapfile -t available_php_versions < <(
    apt-cache pkgnames |
        sed -nE 's/^php([0-9]+\.[0-9]+)-cli$/\1/p' |
        sort -Vu
)

php_version=""
for available_version in "${available_php_versions[@]}"; do
    if php -r 'exit(version_compare($argv[1], $argv[2], ">=") ? 0 : 1);' \
        "${available_version}.0" "${required_php_version}"; then
        php_version="${available_version}"
    fi
done

[[ -n "${php_version}" ]] \
    || fail "No Ubuntu PHP CLI package satisfies the composer.json requirement >= ${required_php_version}."

php_cli_package="php${php_version}-cli"
php_fpm_package="php${php_version}-fpm"
packages_to_install=()

if ! is_installed "${php_cli_package}"; then
    packages_to_install+=("${php_cli_package}")
fi

if ! is_installed "${php_fpm_package}"; then
    packages_to_install+=("${php_fpm_package}")
fi

if (( ${#packages_to_install[@]} > 0 )); then
    log "Installing PHP ${php_version} packages required by composer.json."
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages_to_install[@]}"
fi

php_binary="/usr/bin/php${php_version}"
fpm_service="php${php_version}-fpm"
fpm_socket="/run/php/php${php_version}-fpm.sock"
fpm_binary="/usr/sbin/php-fpm${php_version}"

[[ -x "${php_binary}" ]] || fail "PHP CLI binary not found: ${php_binary}"
[[ -x "${fpm_binary}" ]] || fail "PHP-FPM binary not found: ${fpm_binary}"

installed_php_version="$("${php_binary}" -r 'echo PHP_VERSION;')"
"${php_binary}" -r '
if (!version_compare(PHP_VERSION, $argv[1], ">=")) {
    fwrite(STDERR, "Installed PHP " . PHP_VERSION . " does not satisfy composer.json requirement >= " . $argv[1] . ".\\n");
    exit(1);
}
' "${required_php_version}" \
    || fail "Installed PHP does not satisfy composer.json."
log "Using PHP ${installed_php_version} for CLI and PHP-FPM (composer.json requires >= ${required_php_version})."

awg_binary="$(command -v awg || true)"
[[ -n "${awg_binary}" ]] || fail "The awg command was not found; install AmneziaWG tools first."
awg_binary="$(realpath -e -- "${awg_binary}")"
[[ "${awg_binary}" =~ ^/[A-Za-z0-9._/-]+$ ]] \
    || fail "Unsupported awg binary path: ${awg_binary}"

log "Granting CAP_NET_ADMIN to ${awg_binary} so www-data can run 'awg show' directly."

# '=ep' (not '+ep') so the result is deterministic
setcap cap_net_admin=ep "${awg_binary}" \
    || fail "Could not grant CAP_NET_ADMIN to ${awg_binary}."

getcap "${awg_binary}" | grep -Fq 'cap_net_admin=ep' \
    || fail "CAP_NET_ADMIN was not set on ${awg_binary}."

if ! runuser -u www-data -- "${awg_binary}" show >/dev/null 2>&1; then
    # getcap passes, but the cap doesn't survive exec — diagnose why.
    if findmnt -no OPTIONS --target "${awg_binary}" | tr ',' '\n' | grep -qx 'nosuid'; then
        fail "'${awg_binary}' is on a filesystem mounted with 'nosuid', \
so file capabilities are ignored. Remount without nosuid or install the \
binary under a non-nosuid path."
    fi

    if command -v capsh >/dev/null 2>&1; then
        bnd="$(awk '/^CapBnd:/{print $2}' /proc/self/status)"
        capsh --decode="${bnd}" 2>/dev/null | grep -qw cap_net_admin \
            || fail "CAP_NET_ADMIN is not in the bounding set (typical in Docker). \
Restart the container with --cap-add NET_ADMIN."
    fi

    # Fallback that works in every environment: a narrow sudoers rule.
    log "setcap is ineffective here; falling back to a sudoers rule."
    if ! command -v sudo >/dev/null 2>&1; then
        apt-get install -y sudo >/dev/null 2>&1 \
            || fail "sudo is required for the fallback path."
    fi
    printf 'www-data ALL=(root) NOPASSWD: %s show\n' "${awg_binary}" \
        > /etc/sudoers.d/awg-show
    chmod 0440 /etc/sudoers.d/awg-show
    if ! visudo -cf /etc/sudoers.d/awg-show >/dev/null; then
        rm -f /etc/sudoers.d/awg-show
        fail "Generated sudoers rule failed validation; removed it."
    fi

    runuser -u www-data -- sudo -n "${awg_binary}" show >/dev/null 2>&1 \
        || fail "Could not run 'awg show' as www-data even via sudo."

    log "Fallback active: www-data must call 'sudo -n ${awg_binary} show'."
fi

if ! read -r -p "Absolute path to the application's public directory: " public_dir; then
    fail "Could not read the public-directory path."
fi
[[ -n "${public_dir}" ]] || fail "The public directory cannot be empty."
[[ "${public_dir}" == /* ]] || fail "Enter an absolute path."
[[ -d "${public_dir}" ]] || fail "Directory does not exist: ${public_dir}"

public_dir="$(realpath -e -- "${public_dir}")"
[[ "${public_dir}" != "/" ]] || fail "The filesystem root cannot be used as the public directory."
[[ "${public_dir}" =~ ^/[A-Za-z0-9._/-]+$ ]] \
    || fail "Use a public-directory path containing only letters, numbers, dots, underscores, hyphens, and slashes."
[[ -f "${public_dir}/index.php" ]] || fail "No index.php found in ${public_dir}."

log "Granting www-data access to ${public_dir} using filesystem ACLs."
parent_dir="$(dirname -- "${public_dir}")"
if [[ "${parent_dir}" != "/" ]]; then
    setfacl -m u:www-data:rx "${parent_dir}" \
        || fail "Could not grant www-data access to the application directory ${parent_dir}."
    parent_dir="$(dirname -- "${parent_dir}")"
fi

while [[ "${parent_dir}" != "/" ]]; do
    setfacl -m u:www-data:x "${parent_dir}" \
        || fail "Could not grant www-data traversal permission on ${parent_dir}."
    parent_dir="$(dirname -- "${parent_dir}")"
done

setfacl -R -m u:www-data:rX "${public_dir}" \
    || fail "Could not grant www-data read access to ${public_dir}."
if ! find "${public_dir}" -type d -exec setfacl -m d:u:www-data:rx {} +; then
    fail "Could not configure inherited www-data access under ${public_dir}."
fi

if ! runuser -u www-data -- test -r "${public_dir}/index.php"; then
    fail "www-data still cannot read ${public_dir}/index.php after ACL setup."
fi

sites_available="/etc/nginx/sites-available"
sites_enabled="/etc/nginx/sites-enabled"
site_name="symfony-app"
site_config="${sites_available}/${site_name}"
enabled_config="${sites_enabled}/${site_name}"
managed_marker="# Managed by admin/setup-web.sh"

mkdir -p "${sites_available}" "${sites_enabled}"

if [[ -e "${site_config}" ]] && ! grep -Fxq "${managed_marker}" "${site_config}"; then
    fail "${site_config} already exists and is not managed by this script; refusing to overwrite it."
fi

if [[ -e "${enabled_config}" || -L "${enabled_config}" ]]; then
    [[ -L "${enabled_config}" ]] || fail "${enabled_config} exists and is not a symlink."
    [[ "$(readlink -f -- "${enabled_config}")" == "${site_config}" ]] \
        || fail "${enabled_config} points to a different configuration; refusing to replace it."
fi

temporary_config="$(mktemp "${sites_available}/.${site_name}.XXXXXX")"
backup_config="$(mktemp "${sites_available}/.${site_name}.backup.XXXXXX")"
had_previous_config=0
enabled_link_created=0
disabled_default=0

if [[ -e "${site_config}" ]]; then
    cp -p -- "${site_config}" "${backup_config}"
    had_previous_config=1
fi

restore_default_site() {
    if (( disabled_default == 1 )) && [[ ! -e "${default_enabled}" && ! -L "${default_enabled}" ]]; then
        ln -s "${sites_available}/default" "${default_enabled}"
    fi
}

restore_configuration() {
    if (( enabled_link_created == 1 )); then
        rm -- "${enabled_config}"
    fi

    if (( had_previous_config == 1 )); then
        cp -p -- "${backup_config}" "${site_config}"
    else
        rm -f -- "${site_config}"
    fi

    restore_default_site
}

cleanup() {
    rm -f -- "${temporary_config}" "${backup_config}"
}
trap cleanup EXIT

cat >"${temporary_config}" <<EOF
${managed_marker}
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root ${public_dir};
    index index.php;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ ^/index\\.php(/|$) {
        fastcgi_pass unix:${fpm_socket};
        fastcgi_split_path_info ^(.+\\.php)(/.*)\$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$document_root;
        internal;
    }

    location ~ \\.php\$ {
        return 404;
    }
}
EOF

install -m 0644 "${temporary_config}" "${site_config}"

if [[ ! -e "${enabled_config}" && ! -L "${enabled_config}" ]]; then
    ln -s "${site_config}" "${enabled_config}"
    enabled_link_created=1
fi

default_enabled="${sites_enabled}/default"
if [[ -L "${default_enabled}" ]] \
    && [[ "$(readlink -f -- "${default_enabled}")" == "${sites_available}/default" ]]; then
    rm -- "${default_enabled}"
    disabled_default=1
fi

if ! nginx -t; then
    restore_configuration
    fail "Nginx configuration test failed; services were not restarted."
fi

systemctl enable --now "${fpm_service}" nginx
systemctl reload nginx

[[ -S "${fpm_socket}" ]] || fail "PHP-FPM did not create its expected socket: ${fpm_socket}"

log "Nginx and PHP-FPM are configured and running."
log "Nginx serves ${public_dir} and forwards PHP requests to ${fpm_socket}."
