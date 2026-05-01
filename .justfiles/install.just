set working-directory := ".."

[doc('Install all tools')]
default: _lefthook _convco _actionlint _bats

[group('install')]
[doc('Install git hooks via lefthook')]
hooks:
    lefthook install

[private]
_lefthook:
    brew install lefthook

[private]
_convco:
    brew install convco

[private]
_actionlint:
    brew install actionlint

[private]
_bats:
    brew install bats-core
