SCRIPT_DIR=$(dirname "$0")
if ! command -v pipx &> /dev/null
then
    brew install pipx
    pipx ensurepath
fi
pipx run "$SCRIPT_DIR/add.py" add auto "$@"

