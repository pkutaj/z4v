#!/bin/env/bash

make_z4v() {
    # Parameters
    kbType=$1
    name="${2:-$(read -p "Name: " name && echo "$name")}"
    extract="${3:-$(read -p "Extract: " extract && echo "$extract")}"
    cat="${4:-$(read -p "Category: " cat && echo "$cat")}"
    open="${5:-$(read -p "Open: " open && echo "$open")}"
    url="${6:-$(read -p "URL: " url && echo "$url")}"

    # Get current date
    today=$(date +"%Y-%m-%d")


    # Set template file path
    t="${Z4V_PATH}/page_template.md"
    #
    # Replace <date> in template with the current date
    template=$(cat "$t" | sed "s/<date>/${today:5}/")

    case $kbType in
    "k")
        new_wlog "$name" "$extract" "$cat" "$open" "$url"
        ;;
    "s")
        new_slog "$name" "$extract" "$cat" "$open" "$url"
        ;;
    esac
}

# Function: new-wlog
new_wlog() {
    local name="$1"
    local extract="$2"
    local cat="$3"
    local open="$4"
    local url="$5"

    invalidCharacters="[^-A-Za-z0-9_\.]"
    filename=$(echo "$name" | sed -e "s/ - Jira//" -e "s/$invalidCharacters/-/g" -e "s/.*/&.md/")
    destination="${KB_PATH}/${cat}/${today}-${filename}"
    
    touch "$destination"

    # Insert extracted concept if provided
    if [ -n "$extract" ]; then
        insert_extractedConcept "$extract"
    fi

    # Append URL to destination file
    if [ -n "$url" ]; then
        echo "* $url" >>"$destination"
    fi

    # Open destination file if required
    if [ "$open" = "y" ]; then
        code "$destination"
    fi

    gitPush "$KB_PATH"
}

# Function: new-slog
new_slog() {
    local name="$1"
    local extract="$2"
    local cat="$3"
    local open="$4"
    local url="$5"

    full_slog_name="${cat}-${today}-${filename}"
    destination="${SLOG_PATH}/${full_slog_name}"
    touch "$destination"
    template=$(cat "${Z4V_PATH}"/page_template.md)
    echo "$template" >"$destination"

    # Insert extracted concept if provided
    if [ -n "$extract" ]; then
        insert_extractedConcept "$extract"
    fi

    # Push destination file to Git
    gitPush "$SLOG_PATH"

    # Append URL to destination file
    if [ -n "$url" ]; then
        echo "$url" >>"$destination"
    fi

    # Open destination file if required
    if [ "$open" = "y" ]; then
        code "$destination"
    fi

}

# Function: insert-extractedConcept
insert_extractedConcept() {
    insertSteps=$1
    findSteps=">"
    echo "$destination" | sed "s/$findSteps/$findSteps$insertSteps/"
}

# Function: gitPush
gitPush() {
    repo_path=$1
    cd "$repo_path" || return
    git add "$destination"
    git ls-files --deleted | xargs -I {} git add "{}"
    git commit -m "$destination" && git push
}
