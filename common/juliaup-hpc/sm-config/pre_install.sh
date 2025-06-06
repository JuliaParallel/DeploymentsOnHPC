set -eu

# Rust is a prerequisit of building Juliuaup (which we need to do so we can
# disable selfupdate)

# This script relies on simple-modules setting the RUSTUP_HOME environment
# variable

# Installs Rustup: https://rustup.rs/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Uses Rustup to install the latests stable version
${CARGO_HOME}/bin/rustup install stable
${CARGO_HOME}/bin/rustup set auto-self-update disable
