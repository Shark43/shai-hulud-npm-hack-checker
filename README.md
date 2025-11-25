# npm-hack-checker

A bash script tool to scan Node.js projects for potentially compromised or malicious npm packages by checking both `package.json` and `package-lock.json` files against a blacklist of known bad dependencies.

## Features

- 🔍 Scans multiple projects recursively
- 📦 Checks both `package.json` and `package-lock.json` files
- 📊 Provides detailed statistics with separate counts for each file type
- ⏱️ Tracks execution time
- 🚫 Automatically excludes `node_modules` and `.next` directories
- ✅ Clear status reporting (safe or warnings)

## Prerequisites

- Bash shell (tested on macOS with zsh/bash)
- Node.js and npm installed (for `npm list` command)
- A blacklist file (`bed-npm-list.txt`) containing one package name per line

## Setup

1. Make the script executable:
```bash
chmod +x checker.sh
```

2. Ensure you have a `bed-npm-list.txt` file in the same directory with one package name per line:
```
malicious-package-1
compromised-package-2
suspicious-package-3
```

3. Configure the search directory in `checker.sh`:
```bash
SEARCH_DIRS=("/path/to/your/projects")
```

## Usage

Run the script from the `npm-hack-checker` directory:

```bash
./checker.sh
```

The script will:
1. Find all projects with `package.json` or `package-lock.json` files
2. Check each project against the blacklist
3. Display findings in real-time
4. Show a comprehensive summary at the end

## Output

### During Execution

The script prints progress as it checks each project:
```
Checking /path/to/project...
```

If a suspicious dependency is found, it will display:
- The dependency name via `npm list`
- Context from `package-lock.json` (if found there)

### Summary Report

At the end, you'll see a detailed summary:

```
==========================================
SCAN SUMMARY
==========================================
Projects scanned: 15

Dependencies checked:
  - package.json: 10995
  - package-lock.json: 10995
  - Total: 21990

Possible hacks found:
  - package.json: 0
  - package-lock.json: 0
  - Total: 0

Total time: 45s

✅ STATUS: All clear! No suspicious dependencies found.
==========================================
```

Or if issues are found:

```
⚠️  STATUS: WARNING! Found 2 potentially compromised dependency(ies).
```

## Configuration

### Changing Search Directories

Edit the `SEARCH_DIRS` array in `checker.sh`:

```bash
# Single directory
SEARCH_DIRS=("/Users/username/projects")

# Multiple directories
SEARCH_DIRS=(
    "/Users/username/projects"
    "/Users/username/other-projects"
)
```

### Updating the Blacklist

Edit `bed-npm-list.txt` and add one package name per line. The script will automatically pick up the changes on the next run.

## How It Works

1. **Discovery Phase**: Recursively finds all `package.json` and `package-lock.json` files, excluding `node_modules` and `.next` directories.

2. **Package.json Check**: For projects with `package.json`, uses `npm list --all` to get the complete dependency tree and checks against the blacklist.

3. **Package-lock.json Check**: Directly greps `package-lock.json` files for blacklisted packages, providing context when found.

4. **Statistics**: Tracks separate counts for:
   - Dependencies checked via `package.json`
   - Dependencies checked via `package-lock.json`
   - Hacks found in each file type
   - Total projects scanned
   - Execution time

## Exclusions

The script automatically excludes:
- `node_modules/` directories
- `.next/` build directories (Next.js)

## Troubleshooting

### Permission Denied
```bash
chmod +x checker.sh
```

### Script Not Found
Ensure you're running the script from the correct directory or use the full path:
```bash
/path/to/npm-hack-checker/checker.sh
```

### No Projects Found
- Verify the `SEARCH_DIRS` path is correct
- Ensure projects have `package.json` or `package-lock.json` files
- Check that you have read permissions for the directories

### npm list Errors
Some projects may have corrupted `node_modules` or missing dependencies. The script suppresses these errors and continues scanning.

## Notes

- The script checks both files separately to catch edge cases where a package might be in `package-lock.json` but not properly listed in `package.json`
- Execution time depends on the number of projects and dependencies
- Large projects with many dependencies will take longer to scan

## License

This tool is provided as-is for security scanning purposes.
