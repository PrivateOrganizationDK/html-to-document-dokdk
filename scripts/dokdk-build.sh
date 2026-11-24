#!/usr/bin/env bash
# Builds the fork's packages as one dokdk pre-release: every public package gets the
# version 0.0.0-dokdk-<timestamp>, is built and tested, and is packed into a tarball.
# Writes the tarballs, SHA256SUMS, VERSION and release-notes.md to the output directory
# (default: dokdk-build). .github/workflows/dokdk-build.yml runs it and publishes the
# result as a GitHub release; DOKDK.md describes how to use one.
#
# It versions the working tree in place (package.json files, consumed changesets), so it
# refuses to run on a dirty tree. Undo the versioning afterwards with `git restore .`.
#
# Usage: scripts/dokdk-build.sh [output-dir]
set -euo pipefail

cd "$(dirname "$0")/.."

out_dir="$(realpath -m "${1:-dokdk-build}")"
repo="${GITHUB_REPOSITORY:-PrivateOrganizationDK/html-to-document-dokdk}"

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "The working tree has changes; commit or stash them first." >&2
  exit 1
fi

commit="$(git rev-parse HEAD)"
subject="$(git log -1 --format=%s)"

# Public workspace packages as "name<TAB>path".
packages="$(pnpm ls -r --depth -1 --json | jq -r '.[] | select(.private | not) | "\(.name)\t\(.path)"' | sort)"

# A changeset that bumps every public package, so they all get the snapshot version and
# depend on each other's snapshot versions, also those without a pending changeset.
{
  echo '---'
  cut -f1 <<<"$packages" | sed "s/.*/'&': patch/"
  echo '---'
  echo
  echo 'dokdk build'
} >.changeset/dokdk-build.md

# The configured changelog generator calls GitHub's API for every changeset; a snapshot
# needs no changelog entry.
jq '.changelog = false' .changeset/config.json >.changeset/config.json.tmp
mv .changeset/config.json.tmp .changeset/config.json

pnpm exec changeset version --snapshot dokdk

version="$(jq -r .version packages/core/package.json)"
if [[ "$version" != 0.0.0-dokdk-* ]]; then
  echo "Unexpected snapshot version: $version" >&2
  exit 1
fi

pnpm run build
pnpm run test

rm -rf "$out_dir"
mkdir -p "$out_dir"
while IFS=$'\t' read -r _name path; do
  (cd "$path" && pnpm pack --pack-destination "$out_dir" >/dev/null)
done <<<"$packages"

(cd "$out_dir" && sha256sum -- *.tgz >SHA256SUMS)
echo "$version" >"$out_dir/VERSION"

tag="v$version"
download="https://github.com/$repo/releases/download/$tag"

{
  echo "Pre-release build of the packages at commit $commit (\`$subject\`), for use until these changes are published to npm."
  echo
  echo "Every package carries the version \`$version\`, set with \`changeset version --snapshot dokdk\` and without changelog entries. The packages were built and tested on this commit with \`scripts/dokdk-build.sh\`, and packed with \`pnpm pack\`. No source file differs from the commit."
  echo
  echo "The packages depend on each other by exact version, which npm does not have, so install all of them from this release. With pnpm, add these overrides to \`pnpm-workspace.yaml\`:"
  echo
  echo '```yaml'
  echo 'overrides:'
  while IFS=$'\t' read -r name _path; do
    echo "  $name: $download/$name-$version.tgz"
  done <<<"$packages"
  echo '```'
  echo
  echo 'SHA-256:'
  echo
  echo '```'
  cat "$out_dir/SHA256SUMS"
  echo '```'
} >"$out_dir/release-notes.md"

echo "Built $version into $out_dir"
