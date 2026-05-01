set working-directory := ".."

[doc('Run all tests')]
default: bats

[group('test')]
[doc('Run bats tests — optionally pass a specific file: just test::bats tests/versions.bats')]
[no-exit-message]
bats file='tests/':
    bats {{file}}
