# LICENSE-NOTICE — synapse-omi

`synapse-omi` is a fork of [BasedHardware/omi](https://github.com/BasedHardware/omi),
maintained by WE Mobility Academy GmbH for use inside the SYNAPSE platform.

## Upstream

- **Origin:** https://github.com/BasedHardware/omi
- **License:** MIT — see [`LICENSE`](LICENSE)
- **Copyright (upstream):** © 2024 Based Hardware Contributors

The original MIT `LICENSE` file is preserved unchanged in the repository root.
All re-uses and modifications of upstream code retain the MIT permission and
warranty notices required by the upstream license.

## Fork modifications (this repository)

- **Maintainer:** WE Mobility Academy GmbH (`j.wenk@mobilityacademy.de`)
- **Purpose:** Backend reuse for the SYNAPSE Meeting-Recorder track (N-062).
  See [`Re-Use-Map.md`](Re-Use-Map.md) for the canonical mapping of what is
  inherited, replaced, and added.
- **License of additions:** MIT — same license as upstream. Any code added in
  this fork (e.g. `/stream/dual`, `/transcribe-snippet`, cleanup-provider
  abstraction) is contributed under MIT.

## Attribution requirement

Downstream consumers (including the SYNAPSE monorepo at `Users/jonathan/Claude`)
must retain this notice and the upstream `LICENSE` when distributing binaries
or container images that include code from this repository.

## Contact

For licensing questions: `j.wenk@mobilityacademy.de`.
