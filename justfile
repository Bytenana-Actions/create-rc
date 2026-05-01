mod install '.justfiles/install.just'
mod lint    '.justfiles/lint.just'
mod test    '.justfiles/test.just'

[doc('List available recipes')]
default:
    @just --list --list-submodules

[group('workflow')]
[doc('Install all tools and git hooks — run once after cloning')]
setup:
    @just install
    @just install::hooks

[group('workflow')]
[doc('Run all checks — mirrors CI')]
ci:
    @just lint
    @just test
