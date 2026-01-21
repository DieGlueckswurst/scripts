
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

rmMergeFiles() {
    find . -name "*.orig" -type f -delete
}

openxcode() {
    if [ -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
        open ios/Runner.xcworkspace
        echo "Opening iOS workspace in Xcode..."
    else
        echo "Error: No iOS workspace found. Are you in a Flutter root directory?"
    fi
}
