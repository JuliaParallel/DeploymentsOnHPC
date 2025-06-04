set -eu


# This script relies on simple-modules setting the RUSTUP_HOME environment
# variable

# Installs Rustup: https://rustup.rs/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
