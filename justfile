ROOT_DIR := `dirname "$(realpath '{{justfile_directory()}}')"`

# Run all tests
test: test-bootstrap test-macos test-openrgb test-one-line

# Run bootstrap dry-run test
test-bootstrap:
    bash tests/test-bootstrap-dry-run.sh

# Run macOS dry-run test
test-macos:
    bash tests/test-macos-dry-run.sh

# Run OpenRGB installation test
test-openrgb:
    bash tests/test-install-openrgb.sh

# Run one-line bootstrap test
test-one-line:
    bash tests/test-one-line-bootstrap.sh

# Check bash syntax on all shell scripts
lint:
    find . -name '*.sh' -exec bash -n {} +

# Check syntax on a specific file
lint-file path:
    bash -n '{{path}}'

# Print version
version:
    @git describe --tags --always 2>/dev/null || echo "not a git tag"
