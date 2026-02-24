
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

gsync() {
    # Save current branch
    current_branch=$(git branch --show-current)

    # Detect main branch (main or master)
    if git show-ref --verify --quiet refs/heads/main; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        main_branch="master"
    else
        echo "Error: Neither 'main' nor 'master' branch found."
        return 1
    fi

    # Don't merge into itself
    if [ "$current_branch" = "$main_branch" ]; then
        echo "Already on $main_branch. Just pulling..."
        git pull
        return 0
    fi

    echo "Syncing $current_branch with $main_branch..."

    # Fetch all updates
    git fetch --all

    # Checkout and pull main/master
    git checkout $main_branch
    git pull

    # Switch back and merge
    git checkout $current_branch
    git merge $main_branch

    echo "Done! $main_branch merged into $current_branch"
}
