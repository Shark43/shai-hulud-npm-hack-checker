#!/bin/bash

SEARCH_DIRS=("/Users/Desktop/Projects/")

CWD=$(pwd)
# Read bad dependencies into an array
BAD_DEPS=()
while IFS= read -r line || [ -n "$line" ]; do
    [[ -n "$line" ]] && BAD_DEPS+=("$line")
done < ./bad-npm-list.txt

# Statistics tracking
START_TIME=$(date +%s)
PROJECTS_SCANNED=0
DEPS_CHECKED_PACKAGE_JSON=0
DEPS_CHECKED_PACKAGE_LOCK=0
HACKS_FOUND_PACKAGE_JSON=0
HACKS_FOUND_PACKAGE_LOCK=0

PROJECTS=()
for search_dir in ${SEARCH_DIRS[@]}; do
    # Find projects with package.json (exclude node_modules and .next directories)
    while IFS= read -r -d '' project; do
        PROJECTS+=("$(dirname "$project")")
    done < <(find "$search_dir" \( -path "*/node_modules" -o -path "*/.next" \) -prune -o -name "package.json" -type f -print0)
    # Find projects with package-lock.json (may not have package.json)
    while IFS= read -r -d '' project; do
        project_dir="$(dirname "$project")"
        # Only add if not already in PROJECTS array
        if [[ ! " ${PROJECTS[@]} " =~ " ${project_dir} " ]]; then
            PROJECTS+=("$project_dir")
        fi
    done < <(find "$search_dir" \( -path "*/node_modules" -o -path "*/.next" \) -prune -o -name "package-lock.json" -type f -print0)
done

for project in "${PROJECTS[@]}"; do
    cd "$project"
    echo "Checking $project..."
    ((PROJECTS_SCANNED++))
    
    PROJECT_HACKS=0
    FULL_LIST=""
    HAS_PACKAGE_JSON=false
    HAS_PACKAGE_LOCK=false
    
    # Check which files exist
    [ -f "package.json" ] && HAS_PACKAGE_JSON=true
    [ -f "package-lock.json" ] && HAS_PACKAGE_LOCK=true
    
    # Check via npm list (uses package.json)
    if [ "$HAS_PACKAGE_JSON" = true ]; then
        FULL_LIST=$(npm list --all --silent 2>/dev/null)
        
        for dep in ${BAD_DEPS[@]}; do
            ((DEPS_CHECKED_PACKAGE_JSON++))
            if [ $(echo $FULL_LIST | grep "$dep" | wc -l) != 0 ]; then
                ((PROJECT_HACKS++))
                ((HACKS_FOUND_PACKAGE_JSON++))
                npm list $dep
            fi
        done
    fi
    
    # Also directly check package-lock.json file
    if [ "$HAS_PACKAGE_LOCK" = true ]; then
        for dep in ${BAD_DEPS[@]}; do
            ((DEPS_CHECKED_PACKAGE_LOCK++))
            
            if grep -q "\"$dep\"" package-lock.json 2>/dev/null; then
                # Check if we already found this via npm list
                if [ "$HAS_PACKAGE_JSON" = true ]; then
                    # Check if it was found via npm list
                    if [ -z "$FULL_LIST" ] || [ $(echo $FULL_LIST | grep "$dep" | wc -l) == 0 ]; then
                        # Found in lock file but not in npm list (edge case)
                        ((PROJECT_HACKS++))
                        ((HACKS_FOUND_PACKAGE_LOCK++))
                        echo "Found $dep in package-lock.json (not in npm list)"
                        grep -A 5 -B 5 "\"$dep\"" package-lock.json | head -20
                    fi
                else
                    # No package.json, so this is a new finding
                    ((PROJECT_HACKS++))
                    ((HACKS_FOUND_PACKAGE_LOCK++))
                    echo "Found $dep in package-lock.json"
                    grep -A 5 -B 5 "\"$dep\"" package-lock.json | head -20
                fi
            fi
        done
    fi

    cd "$CWD"
done

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))

# Calculate totals
TOTAL_DEPS_CHECKED=$((DEPS_CHECKED_PACKAGE_JSON + DEPS_CHECKED_PACKAGE_LOCK))
TOTAL_HACKS_FOUND=$((HACKS_FOUND_PACKAGE_JSON + HACKS_FOUND_PACKAGE_LOCK))

# Print summary
echo ""
echo "=========================================="
echo "SCAN SUMMARY"
echo "=========================================="
echo "Projects scanned: $PROJECTS_SCANNED"
echo ""
echo "Dependencies checked:"
echo "  - package.json: $DEPS_CHECKED_PACKAGE_JSON"
echo "  - package-lock.json: $DEPS_CHECKED_PACKAGE_LOCK"
echo "  - Total: $TOTAL_DEPS_CHECKED"
echo ""
echo "Possible hacks found:"
echo "  - package.json: $HACKS_FOUND_PACKAGE_JSON"
echo "  - package-lock.json: $HACKS_FOUND_PACKAGE_LOCK"
echo "  - Total: $TOTAL_HACKS_FOUND"
echo ""
echo "Total time: ${ELAPSED_TIME}s"
echo ""

if [ $TOTAL_HACKS_FOUND -eq 0 ]; then
    echo "✅ STATUS: All clear! No suspicious dependencies found."
else
    echo "⚠️  STATUS: WARNING! Found $TOTAL_HACKS_FOUND potentially compromised dependency(ies)."
fi
echo "=========================================="