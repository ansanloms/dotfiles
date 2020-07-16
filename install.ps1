$ErrorActionPreference = "Stop"

$CONFIG = "install.conf.yaml"
$DOTBOT_DIR = "dotbot"

$DOTBOT_BIN = "bin/dotbot"
$BASEDIR = Convert-Path $(Split-Path $MyInvocation.InvocationName -Parent)

$args_string = $args -join " "

cd "${BASEDIR}"
git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
git submodule update --init --recursive "${DOTBOT_DIR}"

python "${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "$args_string"
