# Keeping the chart up to date and preserving GS specific configuration

The `sync.sh` script is used to keep the chart up to date with the upstream chart and to preserve Giant Swarm specific changes.
We use `vendir` to manage the chart dependencies and `git patch` to apply the Giant Swarm specific changes.

## How to sync the chart with upstream

The `vendir.yml` configuration points to a specific version of the upstream chart.
Running `vendir sync` will sync the `helm` directory in this repository with the version defined there.

1. Update the chart version in the `vendir.yml` file.
2. Run `vendir sync`

## How to maintain Giant Swarm specific changes to upstream values and manifests

This folder contains the `sync.sh` script which does the following:

- Syncs the chart with the upstream chart. (See above)
- Applies all patches in the `patches` directory to the chart.
- Generates the json schema for the chart values.

Generally running the script should be enough to keep the chart up to date with the upstream chart and to preserve Giant Swarm specific changes.

1. Update the chart version in the `vendir.yml` file.
2. Run `./sync.sh`

However, if the upstream chart changes in a way that conflicts with a patch, it might have to be regenerated.

## How to generate a patch

Patches are simply git diffs of the changes made to the upstream chart.

1. Run `vendir sync` to get the latest upstream chart.
2. Commit only the manifest that you want to generate a patch for.
3. Make the Giant Swarm specific changes to the manifest.
4. Run `git diff helm/PATH/TO/MANIFEST > sync/patches/NAME.patch`
5. Run `./sync.sh` to apply all patches.
