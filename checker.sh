SEARCH_DIRS=("/home/username/foobar")

CWD=$(pwd)
BAD_DEPS=$(cat ./bed-npm-list.txt)

PROJECTS=()
for search_dir in ${SEARCH_DIRS[@]}; do
    # Find projects with package.json
    while IFS= read -r -d '' project; do
        PROJECTS+=("$(dirname "$project")")
    done < <(find "$search_dir" -path "*/node_modules" -prune -o -name "package.json" -type f -print0)
    # Find projects with package-lock.json (may not have package.json)
    while IFS= read -r -d '' project; do
        project_dir="$(dirname "$project")"
        # Only add if not already in PROJECTS array
        if [[ ! " ${PROJECTS[@]} " =~ " ${project_dir} " ]]; then
            PROJECTS+=("$project_dir")
        fi
    done < <(find "$search_dir" -path "*/node_modules" -prune -o -name "package-lock.json" -type f -print0)
done

for project in "${PROJECTS[@]}"; do
    cd "$project"
    echo "Checking $project..."
    
    # Check via npm list (uses both package.json and package-lock.json)
    if [ -f "package.json" ]; then
        FULL_LIST=$(npm list --all --silent 2>/dev/null)
        
        for dep in ${BAD_DEPS[@]}; do
            if [ $(echo $FULL_LIST | grep "$dep" | wc -l) != 0 ]; then
                npm list $dep
            fi
        done
    fi
    
    # Also directly check package-lock.json file
    if [ -f "package-lock.json" ]; then
        for dep in ${BAD_DEPS[@]}; do
            if grep -q "\"$dep\"" package-lock.json 2>/dev/null; then
                echo "Found $dep in package-lock.json"
                grep -A 5 -B 5 "\"$dep\"" package-lock.json | head -20
            fi
        done
    fi

    cd "$CWD"
done