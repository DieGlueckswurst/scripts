co() {
    j $1
    code .
}

depfunc() {
    local start_dir
    start_dir=$(pwd)
    local changed_dir=0

    if [[ $(basename "$PWD") == "cloud_functions" ]]; then
        firebase deploy --only functions
        return $?
    fi

    if [[ -d "cloud_functions" ]]; then
        cd cloud_functions || return 1
        changed_dir=1
    elif [[ -d "../cloud_functions" ]]; then
        cd ../cloud_functions || return 1
        changed_dir=1
    else
        echo "depfunc: Ordner 'cloud_functions' nicht gefunden (weder hier noch in ..)."
        return 1
    fi

    firebase deploy --only functions
    local ret=$?
    if [[ $changed_dir -eq 1 ]]; then
        cd "$start_dir" || true
    fi
    return $ret
}
