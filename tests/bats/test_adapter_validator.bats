#!/usr/bin/env bats
# Test suite for adapter validator module
# TDD: Test written BEFORE implementation

setup() {
    load test_helper
    source "$(find_lib_file adapter/validator.sh)"
}

@test "adapter validator: can validate manifest structure" {
    local test_manifest='{"adapters":{"test":{"version":"1.0.0"}}}'
    run validate_manifest_structure "$test_manifest"
    [ "$status" -eq 0 ]
}

@test "adapter validator: rejects invalid manifest" {
    local test_manifest='{"invalid":"data"}'
    run validate_manifest_structure "$test_manifest"
    [ "$status" -eq 1 ]
}

@test "adapter validator: can validate adapter compatibility" {
    run validate_adapter_compatibility "test-adapter" "5.0.0"
    [ "$status" -eq 0 ]
}

@test "adapter validator: can check dependencies" {
    run check_adapter_dependencies "test-adapter"
    [ "$status" -eq 0 ]
}