# Contributing to AEO Toolkit

Thank you for your interest in contributing. This toolkit is maintained by [HarrysonTech](https://harrysontech.xyz) and the community.

## What We Need Most

- **New platform data**: Citation statistics and observed behaviors for AI engines not yet covered
- **Schema templates**: JSON-LD templates for schema types not yet in `templates/`
- **Real-world examples**: Anonymized before/after examples of AEO improvements
- **Script improvements**: Fixes and enhancements to `verify-aeo.sh` and `generate-llms-txt.py`
- **Translations**: The docs in languages other than English

## How to Contribute

### 1. Fork and Clone

```bash
git clone https://github.com/your-username/aeo-toolkit.git
cd aeo-toolkit
```

### 2. Create a Branch

```bash
git checkout -b feature/your-improvement
```

Use a descriptive branch name:
- `fix/robots-txt-detection-bug`
- `docs/add-bing-copilot-section`
- `template/add-localbusiness-schema`
- `example/nextjs-app-router`

### 3. Make Your Changes

Follow these guidelines:

**For documentation** (`docs/`):
- Minimum 1,000 words for new documents
- Include specific, actionable recommendations
- Cite sources for statistics or claims
- Use the existing heading structure (H2 for main sections, H3 for subsections)

**For templates** (`templates/`):
- Use `[PLACEHOLDER]` style for fields users need to fill in
- Include comments explaining what each field does
- Test that JSON files are valid JSON

**For scripts** (`scripts/`):
- Include usage instructions in the file header
- Test on macOS and Linux
- Handle errors gracefully with helpful error messages
- Maintain backward compatibility

**For examples** (`examples/`):
- Must be complete, working HTML/code
- Must include proper Schema.org markup
- Must include a comment explaining what AEO techniques are demonstrated

### 4. Test Your Changes

For script changes:
```bash
# Test verify-aeo.sh
bash scripts/verify-aeo.sh https://example.com

# Test generate-llms-txt.py
python3 scripts/generate-llms-txt.py https://example.com
```

For JSON templates, validate with:
```bash
python3 -c "import json; json.load(open('templates/your-template.json')); print('Valid JSON')"
```

### 5. Submit a Pull Request

- Write a clear PR title: what does this change?
- Include in the PR description:
  - What problem does this solve?
  - How did you test it?
  - Any relevant examples or screenshots

## Style Guidelines

**Markdown**:
- Use `**bold**` for key terms on first use
- Use `code blocks` for all code, commands, and file paths
- Tables for comparisons
- No trailing whitespace

**Code**:
- Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`
- Python: Compatible with Python 3.9+, type hints preferred
- JavaScript: ES2022+, no build step required for scripts

**Tone**:
- Direct and practical — this is a practitioner's toolkit
- Cite sources for statistics
- Acknowledge uncertainty when present ("observed patterns suggest..." not "AI engines always...")

## Reporting Issues

For bugs in scripts: include the URL you tested with (if not sensitive), the command you ran, and the error output.

For outdated information: include a source for the updated information.

For new feature requests: describe the use case, not just the feature.

## Code of Conduct

Be direct, be accurate, be helpful. Debate ideas, not people. Incorrect information should be challenged with evidence, not with hostility.

## License

By contributing, you agree that your contributions will be licensed under the MIT License that covers this project.
