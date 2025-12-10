gaic() {
    echo "Adding all changes..."
    git add .
    
    echo "Opening Cursor for AI commit message generation..."
    open -a "Cursor" .
    
    echo "Next steps:"
    echo "1. In Cursor: Go to Git tab (sidebar)"
    echo "2. Press Cmd+M (or click ✨ icon) to generate AI commit message"
    echo "3. Review/edit the message and commit"
    echo "4. Run 'git push' when ready, or push in Cursor"
}