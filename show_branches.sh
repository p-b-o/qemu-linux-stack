#!/usr/bin/env bash

set -euo pipefail

# generate all local branches for remote ones
for branch in $(git branch -r | grep -v '\->'); do
    git branch --track "${branch#origin/}" "$branch" >& /dev/null || true
done

set -x
git log --all --decorate-refs='refs/heads/*' --oneline --graph --simplify-by-decoration
