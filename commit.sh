#!/bin/bash

COMMIT_MSG="${1:-update blog}"

git add -A
git commit -m "$COMMIT_MSG"
git push