#!/bin/bash

err() {
    echo "::error::$1" >&2
    return 1
}

name="${INPUT_NAME}"
email="${INPUT_EMAIL}"
message="${INPUT_MESSAGE}"
days="${INPUT_DAYS}"
branch="${GITHUB_REF#refs/heads/}"

if [ ! -d .git ]; then
    err "Not a git directory! Did you forget to run actions/checkout before running this action?"
fi

if [ -z "$(git log -1 2>/dev/null)" ]; then
    err "No commits yet!"
fi

if [ -z "${name}" ] || [ -z "${email}" ]; then
    err "Missing input \`name\` and/or \`email\`! Need them to commit."
fi

if [ -z "${message}" ]; then
    err "Missing input \`message\`! Need it as the commit message."
fi

if [ -z "${days}" ]; then
    err "Missing input \`days\`! Need it to calculate the number of days between the latest commit and the new commit."
fi

# https://stackoverflow.com/a/4946875
# https://stackoverflow.com/a/64789296
# Subtract the current UNIX timestamp from the UNIX timestamp of the
# latest committer date and divide by 86400 to get the number of interval days.
time_elapsed=$(( ($(date +%s) - $(git log -1 --format=%ct)) / 86400 ))

# If the number of days between is greater than or equal to the
# number of input days, create a new commit. Otherwise nothing to do.
if [ "$time_elapsed" -ge "${days}" ]; then
    echo "Create a new commit..."
    git config user.name "${name}"
    git config user.email "${email}"
    git commit --allow-empty --message "${message}"
    while !(git push --force-with-lease origin "${branch}"); do
		git fetch origin "${branch}"
		[ -z "$(git diff origin/${branch} ^${branch} --shortstat)" ] && break
		git pull --rebase origin "${branch}"
	done
	activated="true"
else
    echo "Nothing to do..."
	activated="false"
fi

echo "activated=${activated}" >>${GITHUB_OUTPUT}
