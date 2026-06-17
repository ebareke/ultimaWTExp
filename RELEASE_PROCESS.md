# Release process

ultimaWTExp follows [Semantic Versioning](https://semver.org/) and
[Keep a Changelog](https://keepachangelog.com/). One person cuts a release; CI
builds and publishes the artefacts.

## Versioning

- **MAJOR** — breaking changes to parameters, samplesheet schema or outputs.
- **MINOR** — new tools/stages or parameters, backward compatible.
- **PATCH** — bug fixes, doc/CI tweaks.

The version appears in: `nextflow.config` (`manifest.version`), `CITATION.cff`,
`Dockerfile`/`containers/*.def` labels, the CI `VERSION` env, and `CHANGELOG.md`.

## Checklist

1. **Green CI on `dev`** — lint, stub matrix, and the tool-free suite pass.
2. **Bump the version** everywhere listed above (keep them in lockstep).
3. **Update `CHANGELOG.md`** — move `Unreleased` items under the new
   `## [x.y.z] — YYYY-MM-DD` heading.
4. **Refresh docs** if behaviour/parameters changed (USAGE, README, ARCHITECTURE).
5. **Open a PR `dev → main`**, review, merge.
6. **Tag**:
   ```bash
   git tag -a vX.Y.Z -m "ultimaWTExp X.Y.Z"
   git push origin vX.Y.Z
   ```
7. **Containers publish automatically** — the tag triggers `containers.yml`
   (Docker Hub + GHCR). Run `apptainer.yml` (workflow_dispatch) to publish the
   SIF as an `oras://` artifact.
8. **GitHub Release** — create it from the tag; paste the changelog section;
   note the image digests.
9. **Verify** — pull the published image and run `-profile test` end-to-end.

## Artefacts per release

- Source tarball (GitHub auto-generates).
- `ghcr.io/ebareke/ultimawtexp:X.Y.Z` and `:latest` (+ Docker Hub mirror).
- `oras://ghcr.io/ebareke/ultimawtexp-apptainer:X.Y.Z` SIF.
- Updated docs site (`docs/` → GitHub Pages).

## Hotfixes

Branch from the tag (`hotfix/X.Y.(Z+1)`), fix, PR to `main`, tag the patch,
then back-merge to `dev`.
