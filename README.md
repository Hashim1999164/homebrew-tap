# Hashim1999164 Homebrew tap

Homebrew casks for [RufusAdvanced](https://github.com/Hashim1999164/RufusAdvanced) — create bootable USB drives for
macOS, Windows and Linux on a Mac, with every Rufus option.

## Install

```bash
brew install --cask hashim1999164/tap/rufusadvanced
```

or

```bash
brew tap hashim1999164/tap
brew install --cask rufusadvanced
```

Update with `brew upgrade --cask rufusadvanced`, remove with `brew uninstall --cask rufusadvanced`
(add `--zap` to also remove caches, logs and preferences).

The cask installs `RufusAdvanced.app` in /Applications, clears the download quarantine (the app is ad-hoc signed, not
notarized) and links the command line tool as `rufusadv`.

## Maintainers

The cask is generated from
[`Packaging/homebrew/rufusadvanced.rb.in`](https://github.com/Hashim1999164/RufusAdvanced/blob/main/Packaging/homebrew/rufusadvanced.rb.in)
by `scripts/update-cask.sh <version>` in the RufusAdvanced repository after each release.
