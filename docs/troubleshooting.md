# living-docs Troubleshooting Guide

*Comprehensive solutions for common installation, update, and runtime issues*

## 🔍 Quick Diagnosis

Before diving into specific issues, run these diagnostic commands:

```bash
# Check system and project status
./scripts/check-drift.sh --dry-run
./scripts/build-context.sh
ls -la .living-docs.config

# Enable debug mode for detailed logging
export LIVING_DOCS_DEBUG=1
export LIVING_DOCS_DEBUG_LEVEL=TRACE
export LIVING_DOCS_DEBUG_FILE="/tmp/living-docs-debug.log"
```

---

## 1. Installation Issues

### **Problem: Permission denied during installation**
```
bash: ./wizard.sh: Permission denied
curl: (23) Failed writing body
```

**Solutions:**
```bash
# Fix: Download and run with proper permissions
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash

# Alternative: Download first, then run
curl -sSL -o wizard.sh https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh
chmod +x wizard.sh
./wizard.sh

# For write permission issues in target directory
sudo chown -R $USER:$USER .
chmod 755 .
```

### **Problem: Missing template files during installation**
```
Error: Template file not found: templates/PROJECT.md.template
```

**Solutions:**
```bash
# Verify wizard.sh integrity
curl -sSL https://api.github.com/repos/joshwegener/living-docs/releases/latest

# Re-download and reinstall
rm -f wizard.sh
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash

# Manual recovery: create missing config
echo 'DOCS_PATH="docs"' > .living-docs.config
echo 'INSTALLED_SPECS=""' >> .living-docs.config
```

### **Problem: Auto-detection fails for project type**
```
Warning: Could not detect project type
```

**Solutions:**
```bash
# Force manual selection
./wizard.sh --manual-select

# Create detection hints for your project type
touch requirements.txt    # Python
touch package.json       # Node.js
touch Cargo.toml         # Rust
touch go.mod             # Go

# Override detection in config
echo 'PROJECT_TYPE="custom"' >> .living-docs.config
```

---

## 2. Update Problems

### **Problem: Version mismatch between local and remote**
```
Local version: 2.0.0, Remote version: v0.0.47
Update failed: Version format mismatch
```

**Solutions:**
```bash
# Check current versions
grep "VERSION=" wizard.sh
./adapters/check-updates.sh --dry-run

# Force update with cleanup
rm -rf .living-docs.backup
./wizard.sh --force-update

# Manual version sync
echo 'LIVING_DOCS_VERSION="5.0.1"' > VERSION
```

### **Problem: Update breaks existing configuration**
```
Error: .living-docs.config format changed
```

**Solutions:**
```bash
# Create backup before update
./scripts/check-drift.sh --backup

# Restore from backup if needed
ls .living-docs.backup/
cp .living-docs.backup/latest/.living-docs.config .

# Migrate old config format
sed -i.bak 's/OLD_FORMAT/NEW_FORMAT/g' .living-docs.config
```

### **Problem: Adapter update fails**
```
Error: Could not update spec-kit adapter
Permission denied: .claude/commands/
```

**Solutions:**
```bash
# Fix adapter permissions
find .claude -type d -exec chmod 755 {} \;
find .claude -type f -exec chmod 644 {} \;

# Reinstall specific adapter
./wizard.sh --adapter spec-kit --reinstall

# Clear adapter cache
rm -rf .living-docs.cache/adapters/
```

---

## 3. Adapter-Specific Issues

### **Problem: Spec-Kit adapter installs to wrong directory**
```
Expected: .cursor/rules/
Actual: .claude/commands/
```

**Solutions:**
```bash
# Check AI detection
echo "Current AI: $(cat .living-docs.config | grep AI_TYPE)"

# Override AI detection
echo 'AI_TYPE="cursor"' >> .living-docs.config

# Manually move files
mkdir -p .cursor/rules/
mv .claude/commands/* .cursor/rules/ 2>/dev/null || true
```

### **Problem: BMAD adapter not working**
```
Error: BMAD adapter not implemented
```

**Solutions:**
```bash
# Check adapter status
ls -la adapters/bmad-method/

# Install from template
./wizard.sh --adapter bmad-method

# Manual installation
mkdir -p bmad-method/agents/
cp templates/bmad/* bmad-method/ 2>/dev/null || true
```

### **Problem: Agent-OS adapter missing files**
```
Error: Agent OS adapter not implemented
Required: agents/os/standards/
```

**Solutions:**
```bash
# Create required structure
mkdir -p agent-os/{specs,standards,agents}

# Install adapter
./wizard.sh --adapter agent-os

# Verify installation
ls -la agent-os/
```

---

## 4. Permission Errors

### **Problem: Cannot write to system directories**
```
Permission denied: /usr/local/bin/living-docs
```

**Solutions:**
```bash
# Install to user directory instead
export PATH="$HOME/.local/bin:$PATH"
mkdir -p ~/.local/bin
cp wizard.sh ~/.local/bin/living-docs

# Fix ownership recursively
sudo chown -R $USER:$USER ~/.living-docs

# Use sudo only when necessary
sudo chmod 755 /usr/local/bin/
```

### **Problem: Read-only filesystem**
```
Read-only file system: Cannot create .living-docs.config
```

**Solutions:**
```bash
# Check filesystem status
mount | grep "$(pwd)"

# Remount with write permissions (if you have sudo)
sudo mount -o remount,rw /

# Use alternative configuration location
export LIVING_DOCS_CONFIG_PATH="$HOME/.config/living-docs.config"
```

---

## 5. Network/Connectivity Problems

### **Problem: GitHub API rate limiting**
```
API rate limit exceeded for IP address
```

**Solutions:**
```bash
# Use GitHub token for higher rate limits
export GITHUB_TOKEN="your_token_here"

# Check rate limit status
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/rate_limit

# Wait for rate limit reset
echo "Rate limit resets at: $(date -d @$(curl -s https://api.github.com/rate_limit | grep -o '"reset":[0-9]*' | cut -d':' -f2))"

# Use local installation instead
git clone https://github.com/joshwegener/living-docs.git
cd living-docs && ./wizard.sh
```

### **Problem: Corporate firewall blocks downloads**
```
curl: (7) Failed to connect to raw.githubusercontent.com
```

**Solutions:**
```bash
# Try alternative download methods
wget https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh

# Use proxy if available
export https_proxy="http://proxy.company.com:8080"
curl --proxy $https_proxy -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh

# Download through browser and transfer
# 1. Visit: https://github.com/joshwegener/living-docs
# 2. Download ZIP
# 3. Extract and run: ./wizard.sh
```

### **Problem: SSL certificate verification fails**
```
curl: (60) SSL certificate problem: certificate verify failed
```

**Solutions:**
```bash
# Update certificates (recommended)
sudo apt-get update && sudo apt-get install ca-certificates  # Ubuntu/Debian
brew update && brew install ca-certificates                  # macOS

# Temporary workaround (NOT recommended for production)
curl -k -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash

# Use specific CA bundle
curl --cacert /etc/ssl/certs/ca-certificates.crt -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh
```

---

## 6. Cross-Platform Issues (macOS vs Linux)

### **Problem: sed commands fail on different platforms**
```
sed: invalid command code R    # macOS
sed: can't read s///: No such file or directory    # Linux
```

**Solutions:**
```bash
# Check platform and adjust
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS requires different sed syntax
    sed -i '' 's/old/new/g' file.txt
else
    # Linux standard syntax
    sed -i 's/old/new/g' file.txt
fi

# Use portable alternatives
# Instead of sed -i, use:
cp file.txt file.txt.bak
sed 's/old/new/g' file.txt.bak > file.txt

# Or use perl for better portability
perl -i -pe 's/old/new/g' file.txt
```

### **Problem: Path differences between platforms**
```
Error: /Users/username not found    # Linux running macOS paths
Error: /home/username not found     # macOS running Linux paths
```

**Solutions:**
```bash
# Use environment-aware paths
HOME_DIR="$HOME"
USER_CONFIG="$HOME/.config"
USER_DOCS="$HOME/Documents"

# Detect platform and set paths
case "$OSTYPE" in
    darwin*)  CONFIG_DIR="$HOME/Library/Application Support" ;;
    linux*)   CONFIG_DIR="$HOME/.config" ;;
    *)        CONFIG_DIR="$HOME/.living-docs" ;;
esac

# Use relative paths when possible
DOCS_PATH="./docs"
RELATIVE_CONFIG="./.living-docs.config"
```

### **Problem: Different shell behaviors**
```
bash: array assignment requires bash 4.0+    # macOS has bash 3.2
```

**Solutions:**
```bash
# Check bash version
echo $BASH_VERSION

# Install modern bash on macOS
brew install bash
echo "/usr/local/bin/bash" | sudo tee -a /etc/shells
chsh -s /usr/local/bin/bash

# Write portable shell scripts
# Avoid associative arrays on older bash
# Use simpler data structures instead
```

---

## 7. Debug Mode Usage

### **Enable comprehensive debugging**
```bash
# Basic debug mode
export LIVING_DOCS_DEBUG=1

# Advanced debugging with levels
export LIVING_DOCS_DEBUG=1
export LIVING_DOCS_DEBUG_LEVEL=TRACE  # ERROR, WARN, INFO, TRACE
export LIVING_DOCS_DEBUG_FILE="/tmp/living-docs-debug.log"

# Debug specific operations
LIVING_DOCS_DEBUG=1 ./wizard.sh
LIVING_DOCS_DEBUG=1 ./scripts/check-drift.sh

# Monitor debug output in real-time
tail -f /tmp/living-docs-debug.log
```

### **Debug output analysis**
```bash
# Filter debug logs by level
grep "ERROR\|WARN" /tmp/living-docs-debug.log

# Find timing bottlenecks
grep "TIMING:" /tmp/living-docs-debug.log

# Track function calls
grep ">>> Starting\|<<< Ending" /tmp/living-docs-debug.log

# Extract error context
grep -A 5 -B 5 "ERROR" /tmp/living-docs-debug.log
```

---

## 8. Rollback Procedures

### **Emergency rollback to previous state**
```bash
# List available snapshots
ls -la .living-docs.backup/

# Restore from latest backup
./lib/backup/rollback.sh restore latest

# Restore from specific snapshot
./lib/backup/rollback.sh restore snapshot_20250920_143022

# Create manual backup before changes
./lib/backup/rollback.sh snapshot "Before major update"
```

### **Rollback specific components**
```bash
# Rollback configuration only
cp .living-docs.backup/latest/.living-docs.config .

# Rollback documentation structure
rm -rf docs/
cp -r .living-docs.backup/latest/docs/ .

# Rollback adapters
rm -rf adapters/
cp -r .living-docs.backup/latest/adapters/ .

# Rollback to clean state
git checkout HEAD -- .
git clean -fd
```

### **Version-specific rollbacks**
```bash
# Rollback to specific version
git tag -l "v*" | sort -V
git checkout v5.0.0

# Rollback adapter to previous version
cd adapters/spec-kit/
git log --oneline -10
git checkout abc123def -- .

# Emergency: remove all living-docs components
rm -rf .living-docs* docs/bootstrap.md .claude/ .cursor/
```

---

## 9. Drift Detection and Resolution

### **Problem: Documentation drift detected**
```
Warning: Found 5 orphaned files
Warning: 3 broken links detected
```

**Solutions:**
```bash
# Run drift detection with details
./scripts/check-drift.sh --verbose

# Auto-fix common issues
./scripts/check-drift.sh

# Dry-run to see what would be fixed
./scripts/check-drift.sh --dry-run

# Manual drift resolution
grep -r "broken-link" docs/
find docs/ -name "*.md" -type f -exec grep -l "missing-file" {} \;
```

### **Problem: Orphaned spec files not linked**
```
Found orphaned files:
  - specs/004-living-docs-review/spec.md
  - docs/issues/adapter-version-mismatch.md
```

**Solutions:**
```bash
# Link orphaned specs to current.md
echo "- [Spec 004](../specs/004-living-docs-review/spec.md) - Description" >> docs/current.md

# Link orphaned issues to bugs.md
echo "- [ ] Issue description → [details](issues/adapter-version-mismatch.md)" >> docs/bugs.md

# Auto-fix with drift checker
./scripts/check-drift.sh --auto-fix
```

---

## 10. Performance Issues with Large Projects

### **Problem: Slow documentation processing**
```
Processing large documentation tree: 2000+ files
Operation timeout after 60 seconds
```

**Solutions:**
```bash
# Optimize for large projects
export LIVING_DOCS_BATCH_SIZE=50
export LIVING_DOCS_PARALLEL_JOBS=4

# Exclude large directories from processing
echo "node_modules/" >> .living-docs-ignore
echo "vendor/" >> .living-docs-ignore
echo ".git/" >> .living-docs-ignore

# Use incremental processing
./scripts/check-drift.sh --incremental
./scripts/build-context.sh --cache
```

### **Problem: Memory usage too high**
```
Out of memory: Cannot process documentation tree
```

**Solutions:**
```bash
# Reduce memory footprint
export LIVING_DOCS_MAX_FILE_SIZE=1048576  # 1MB limit
export LIVING_DOCS_MAX_DEPTH=10           # Limit directory depth

# Process in chunks
find docs/ -name "*.md" | head -100 | xargs ./scripts/process-docs.sh

# Clean up temporary files
rm -rf /tmp/living-docs-*
find . -name "*.tmp" -delete
```

### **Performance monitoring**
```bash
# Monitor resource usage
top -p $(pgrep -f living-docs)

# Profile script execution
time ./wizard.sh
time ./scripts/check-drift.sh

# Identify bottlenecks with debug timing
LIVING_DOCS_DEBUG=1 ./scripts/build-context.sh 2>&1 | grep "TIMING:"
```

---

## 🚨 Emergency Recovery

### **Complete system recovery**
```bash
# 1. Stop all living-docs processes
pkill -f living-docs

# 2. Backup current state
tar -czf emergency-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  .living-docs* docs/ specs/ .claude/ .cursor/ 2>/dev/null || true

# 3. Clean installation
rm -rf .living-docs* docs/bootstrap.md .claude/ .cursor/
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash

# 4. Restore custom documentation
tar -xzf emergency-backup-*.tar.gz docs/custom/ 2>/dev/null || true
```

### **Get help**
```bash
# Generate diagnostic report
{
    echo "=== SYSTEM INFO ==="
    uname -a
    echo "Bash version: $BASH_VERSION"

    echo "=== PROJECT STATUS ==="
    ls -la .living-docs*
    cat .living-docs.config 2>/dev/null || echo "No config found"

    echo "=== DEBUG LOG ==="
    tail -50 /tmp/living-docs-debug.log 2>/dev/null || echo "No debug log"

    echo "=== GIT STATUS ==="
    git status 2>/dev/null || echo "Not a git repository"

} > living-docs-diagnostic.txt

echo "Diagnostic report saved to: living-docs-diagnostic.txt"
echo "Please share this file when reporting issues at:"
echo "https://github.com/joshwegener/living-docs/issues"
```

---

## 📞 Support Resources

- **GitHub Issues**: https://github.com/joshwegener/living-docs/issues
- **Documentation**: [docs/current.md](./current.md)
- **Bug Reports**: [docs/bugs.md](./bugs.md)
- **Debug Logs**: Enable with `LIVING_DOCS_DEBUG=1`

---

*Last updated: September 20, 2025*
*For urgent issues, create a diagnostic report and open a GitHub issue*