# Data Model: Adapter Installation System

## Core Entities

### Adapter
Represents a framework integration package.

**Attributes**:
- `name`: String - Unique identifier (e.g., "spec-kit", "bmad", "aider")
- `version`: String - Semantic version (e.g., "0.0.47")
- `source_url`: String - GitHub or git repository URL
- `prefix_enabled`: Boolean - Whether to prefix commands (default: auto-detect)
- `prefix`: String - Namespace prefix if enabled (e.g., "speckit_")
- `dependencies`: Array<String> - Required system commands (e.g., ["git", "sed"])

**Relationships**:
- Has many InstalledFiles
- Has one Manifest
- Has many Commands
- Has many Agents (optional)

### Manifest
Installation record tracking all adapter artifacts.

**Attributes**:
- `adapter_name`: String - Reference to Adapter
- `version`: String - Installed version
- `installed_date`: ISO8601 - Installation timestamp
- `updated_date`: ISO8601 - Last update timestamp (nullable)
- `install_path`: String - Root directory of installation
- `customizations`: Integer - Count of user-modified files

**Relationships**:
- Belongs to one Adapter
- Has many InstalledFiles
- Has many PathMappings

### InstalledFile
Individual file installed by an adapter.

**Attributes**:
- `path`: String - Relative path from project root
- `original_path`: String - Original path in adapter source
- `checksum`: String - SHA256 hash of file contents
- `file_type`: Enum - [command, script, template, agent, config]
- `customized`: Boolean - User has modified file
- `original_checksum`: String - Checksum before customization

**Relationships**:
- Belongs to one Manifest
- Has many PathReferences

### PathMapping
Transformation rule for path rewriting.

**Attributes**:
- `pattern`: String - Regular expression to match
- `replacement`: String - Replacement with variables
- `file_glob`: String - Files to apply mapping to
- `validation_rule`: String - Post-rewrite validation

**Examples**:
```
pattern: "scripts/bash/"
replacement: "{{SCRIPTS_PATH}}/bash/"
file_glob: "**/*.md"
```

### Command
AI assistant command file.

**Attributes**:
- `name`: String - Original command name
- `prefixed_name`: String - Name with adapter prefix
- `ai_tool`: Enum - [claude, cursor, aider, copilot, continue]
- `install_path`: String - AI-specific directory path
- `conflicts_with`: Array<String> - Other commands with same name

**Relationships**:
- Belongs to one Adapter
- References one InstalledFile

### Agent
AI assistant agent definition.

**Attributes**:
- `name`: String - Agent identifier
- `ai_tool`: Enum - [claude, cursor, copilot]
- `definition_format`: Enum - [yaml, json, markdown]
- `install_directory`: String - AI-specific agents directory

**Relationships**:
- Belongs to one Adapter
- References one InstalledFile

## State Transitions

### Adapter States
```
available → downloading → validating → installing → installed
                ↓             ↓            ↓
            download_failed  invalid   install_failed

installed → checking_updates → updating → installed
                              ↓
                          update_failed → installed
```

### File States
```
new → installed → customized
         ↓            ↓
      updated    preserved
```

## Validation Rules

### Adapter Validation
- Name must be lowercase, alphanumeric with hyphens
- Version must follow semantic versioning
- Source URL must be valid git repository
- Prefix must be valid identifier characters

### Path Validation
- No absolute paths except system commands
- All project paths must use defined variables
- No path traversal patterns (../)
- Scripts must be executable after rewrite

### Command Validation
- Command names must end with .md
- Prefixed names must not exceed 255 characters
- No special characters except underscore and hyphen

### Manifest Validation
- All referenced files must exist
- Checksums must match for non-customized files
- No duplicate file paths
- Version must match adapter version

## Relationships Diagram
```
Adapter (1) ←→ (1) Manifest
   ↓                    ↓
   (n)               (n)
Commands         InstalledFiles
                       ↓
                    (n)
                PathReferences

Adapter (1) ←→ (n) Agents
            ↑
            (n)
       PathMappings
```

## Storage Format

### Manifest File Location
```
adapters/[adapter-name]/.living-docs-manifest.json
```

### Manifest JSON Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["adapter", "version", "installed", "files"],
  "properties": {
    "adapter": {"type": "string"},
    "version": {"type": "string"},
    "installed": {"type": "string", "format": "date-time"},
    "updated": {"type": "string", "format": "date-time"},
    "prefix": {"type": "string"},
    "files": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "required": ["checksum", "customized"],
        "properties": {
          "checksum": {"type": "string"},
          "customized": {"type": "boolean"},
          "original_path": {"type": "string"},
          "original_checksum": {"type": "string"}
        }
      }
    },
    "commands": {
      "type": "array",
      "items": {"type": "string"}
    },
    "agents": {
      "type": "array",
      "items": {"type": "string"}
    }
  }
}
```

---
*Data model supports all functional requirements with room for extension*