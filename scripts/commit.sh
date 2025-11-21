#!/bin/bash

COMMIT_MSG="${1:-updated blog posts}"

git add -A
git commit -m "$COMMIT_MSG"
git push