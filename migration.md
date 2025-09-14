# Migration Notice

## 🔮 New Unified Wizard

We've simplified everything into one intelligent wizard!

### Old Scripts (Deprecated)
- `setup.sh` - Now part of wizard
- `repair.sh` - Now part of wizard

### New Way - Just One Command
```bash
./wizard.sh
```

The wizard intelligently:
- Detects if you're in a new or existing project
- Offers appropriate options based on context
- Guides you through all choices
- Sets up everything correctly

### For Existing Users
If you have scripts referencing the old commands, the wizard handles all the same functionality and more:
- New project setup → wizard detects empty directory
- Existing project repair → wizard detects existing files
- Reconfiguration → wizard detects .living-docs.config

### Benefits
- One script to remember
- Intelligent auto-detection
- Better user experience
- Cleaner codebase

---
*The old scripts remain for backward compatibility but will be removed in v2.0*