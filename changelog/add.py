#!/usr/bin/env python3

# aka changelog.py
# This script is used to manage the changelog of the project.
# see https://github.com/Bling-Services/bling_app/wiki/Scripts#changelog-gachl-and-chlog

# /// script
# dependencies = ["requests"]
# ///
import sys
import os
import argparse
import json
from linear_api_utils import get_title_from_linear

workspace_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
print(f"Workspace root: {workspace_root}") 
changelog_dir = os.path.join(workspace_root, 'changes')
next_dir = os.path.join(changelog_dir, 'next')


def build_changelog():
    changelog = []
    
    changelog_folders = sorted(os.listdir(changelog_dir))
    version_folders = [folder for folder in changelog_folders if folder != 'next' and os.path.isdir(os.path.join(changelog_dir, folder))]
    newest_version = sorted(version_folders, key=lambda s: list(map(int, s.split('.'))))[-1]
    next_version = newest_version.split('.')
    next_version[-1] = str(int(next_version[-1]) + 1)
    next_version = '.'.join(next_version)
    
    changelog_folders.reverse()
    for folder in changelog_folders:
        folder_path = os.path.join(changelog_dir, folder)
        if os.path.isdir(folder_path) and folder == 'next':
            changelog.append(f"\n## {next_version}")
            for file in sorted(os.listdir(folder_path)):
                file_path = os.path.join(folder_path, file)
                if os.path.isfile(file_path):
                    with open(file_path, 'r') as f:
                        content = f.read().strip()
                    file_name = os.path.splitext(file)[0]
                    changelog.append(f" - ({file_name}): {content}")
    
    release_note = {
        "language": "de-DE",
        "text": changelog,
    }
    
    os.rename(next_dir, os.path.join(changelog_dir, next_version))
    with open(os.path.join(workspace_root, 'app', 'release_notes.json'), 'w') as f:
        json.dump(release_note, f, indent=4)
    
    old_changelog_path = os.path.join(workspace_root, 'changelog.md')
    if os.path.exists(old_changelog_path):
        with open(old_changelog_path, 'r') as f:
            old_changelog = f.read().strip()
        changelog.append('\n'+old_changelog)
    
    with open(os.path.join(workspace_root, 'changelog.md'), 'w') as f:
        f.write('\n'.join(changelog))
    print("Changelog built.")

def add_to_changelog(name, info=None, no_overwrite=False):
    # put a file called $name.md in the changelog /next directory

    emoji = '🔧'
    if name == 'auto':
        # get the current branch name
        name = os.popen('git rev-parse --abbrev-ref HEAD').read().strip()
        # strip the 'feature/' or 'bugfix/' prefix if it exists
        if name.startswith('bugfix/'):
            name = name[7:]
            emoji = '🐛'
        elif name.startswith('feature/'):
            name = name[8:]
            emoji = '✨'
        
    if not os.path.exists(next_dir):
        os.makedirs(next_dir)

    print(f"Adding {name} to the changelog.")
    
    if '/' in name:
        name, suffix = name.split('/', 1)
        info = f"{suffix} {info}" if info else suffix
    
    file_path = os.path.join(next_dir, f'{name}.md')
    
    if no_overwrite and os.path.exists(file_path.strip()):
        print(f"File {file_path} already exists and --no-overwrite is set. Skipping.")
        return
    
    with open(file_path, 'w') as f:
        # if name is starting with 'dev-' then its probably a linear ticket
        # so write a link like https://linear.app/blingos/issue/DEV-1543 to the file
        # we don't need the link because this makes the file very long and unreadable for the release notes json file
        # if name.startswith('dev-'):
        #     f.write(f'{emoji}: [{info if info else name}](https://linear.app/blingos/issue/{name})')
        if name.startswith('dev-'):
            # Probably a Linear ticket, so get the title via `get_linear_issue.py`
            formatted_title = get_title_from_linear(name)
            if formatted_title is None:
                f.write(f'{emoji}: {info if info else name}')
            else:
                f.write(formatted_title)    
        else:
            f.write(emoji + f': {info}' if info else '')

def main():
    parser = argparse.ArgumentParser(description="Manage changelog, see https://github.com/Bling-Services/bling_app/wiki/Scripts#changelog-gachl-and-chlog")
    subparsers = parser.add_subparsers(dest="command")

    build_parser = subparsers.add_parser('build', help="Build the changelog")
    
    add_parser = subparsers.add_parser('add', help="Add an entry to the changelog")
    add_parser.add_argument('name', help="Name of the changelog entry, or 'auto' to use the current branch name")
    add_parser.add_argument('info', nargs='?', help="Additional information for the changelog entry")
    add_parser.add_argument('--no-overwrite', action='store_true', help="Do not overwrite existing changelog entry")

    args = parser.parse_args()

    if args.command == 'build':
        build_changelog()
    elif args.command == 'add':
        add_to_changelog(args.name, args.info, args.no_overwrite)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()