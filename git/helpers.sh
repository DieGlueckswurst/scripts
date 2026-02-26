
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
    current_branch=$(git branch --show-current)

    if git show-ref --verify --quiet refs/heads/main; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        main_branch="master"
    else
        echo "Error: Neither 'main' nor 'master' branch found."
        return 1
    fi

    if [ "$current_branch" = "$main_branch" ]; then
        echo "Already on $main_branch. Just pulling..."
        git pull
        return 0
    fi

    git add .
    if ! git diff --cached --quiet; then
        echo "Committing and pushing current changes..."
        git commit -m "chore: before sync with $main_branch"
        git push
    fi

    echo "Syncing $current_branch with $main_branch..."
    git fetch --all
    git checkout $main_branch
    git pull
    git checkout $current_branch

    if git merge $main_branch; then
        git push
        echo "Done! $main_branch merged into $current_branch and pushed."
    else
        echo ""
        echo "Merge conflicts detected!"
        echo "Resolve them (e.g. via Cursor chat), then run: gsyncdone"
    fi
}

gsyncdone() {
    git add .
    git commit -m "chore: resolved merge conflicts"
    git push
    echo "Done! Merge resolution committed and pushed."
}
