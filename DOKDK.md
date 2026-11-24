# dokdk builds

This fork publishes its packages as GitHub pre-releases, so projects can use changes before they are published to npm.

## Publishing a build

In the Actions tab, run the **dokdk build** workflow on the branch to build (usually `main`). It runs `scripts/dokdk-build.sh`, which:

1. gives every public package the version `0.0.0-dokdk-<timestamp>` with `changeset version --snapshot dokdk`, without changelog entries,
2. builds and tests the packages,
3. packs each package with `pnpm pack`.

The workflow then publishes the tarballs and their `SHA256SUMS` as the pre-release `v0.0.0-dokdk-<timestamp>`, tagged at the built commit. Nothing is committed.

To build locally instead, run `scripts/dokdk-build.sh [output-dir]` on a clean working tree, then undo the versioning with `git restore .`.

## Using a build

The packages depend on each other by exact version, which npm does not have, so a project installs all of them from the same release. Each release's notes have the pnpm `overrides` to paste into `pnpm-workspace.yaml`; to update, replace them with the newer release's.
