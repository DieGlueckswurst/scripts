
rmIgnoredFiles() {
    git rm -r --cached .
    git add .
    git commit -m "Drop files from .gitignore"
}

rmTag() {
    git tag -d $1
    git push --delete upstream $1
}

rmOldBranches() {
    for branch in $(git branch); 
    do
    if [[ $branch != *"master"* ]] && [[ $branch != *"dev"* ]] && [[ $branch != *"staging"* ]]; then
         git branch -d $branch
    fi
    done
}
