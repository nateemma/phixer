#!/usr/bin/sh

# add the new files:
git diff --name-only --cached | xargs -n 1 git add -v

# add the modified files:
git status -s | grep " M " | awk '{ print $2 }' | xargs -n 1 git add -v
