co() {
    j $1
    code .
}

depfunc() {
    local start_dir
    start_dir=$(pwd)
    local changed_dir=0

    # Deploy läuft immer im Verzeichnis mit firebase.json (Projektroot)
    if [[ -f "firebase.json" ]]; then
        firebase deploy --only functions
        return $?
    fi

    # Wir sitzen im functions/ oder cloud_functions/ Unterordner → ein Verzeichnis hoch
    if [[ $(basename "$PWD") == "functions" || $(basename "$PWD") == "cloud_functions" ]]; then
        if [[ -f "../firebase.json" ]]; then
            cd .. || return 1
            changed_dir=1
        fi
    fi

    if [[ ! -f "firebase.json" ]]; then
        echo "depfunc: Kein firebase.json gefunden (weder hier noch im Parent). Kein Firebase-Projekt?"
        return 1
    fi

    firebase deploy --only functions
    local ret=$?
    if [[ $changed_dir -eq 1 ]]; then
        cd "$start_dir" || true
    fi
    return $ret
}
