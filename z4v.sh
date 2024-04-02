#!/bin/env/bash
make_z4v() {
    kbType=$1
    name="${2:-$(read -p "Name: " name && echo "$name")}"
    extract="${3:-$(read -p "Extract: " extract && echo "$extract")}"
    category="${4:-$(read -p "Category: " category && echo "$category")}"
    open="${5:-$(read -p "Open: " open && echo "$open")}"
    url="${6:-$(read -p "URL: " url && echo "$url")}"
    read -p "Add to backlog? (y/N): " backlog

    today=$(date +"%Y-%m-%d")
    invalidCharacters="[^-A-Za-z0-9_\.]"
    template=$(cat "${Z4V_PATH}"/page_template.md)

    case $kbType in
    "k")
        filename=$(echo "$name" | sed -e "s/ - Jira//" -e "s/$invalidCharacters/-/g" -e "s/.*/&.md/")
        filename="${today}-${filename}"
        destination="${KB_PATH}/${category}/${filename}"
        repo="${KB_PATH}"
        ;;
    "s")
        filename=$(echo "$name" | sed -e "s/ - Jira//" -e "s/$invalidCharacters/-/g" -e "s/.*/&.md/")
        filename="${category}-${today}-${filename}"
        destination="${SLOG_PATH}/${filename}"
        repo="${SLOG_PATH}"
        ;;
    esac

    touch "$destination"
    echo "$template" >"$destination"
    gitPush "$repo"

    if [ -n "$extract" ]; then echo "- [ ] $extract" >>"$destination"; else echo "- [ ] " >>"$destination"; fi
    if [ -n "$url" ]; then echo -e "$url\n\n$(cat "$destination")" >"$destination"; fi
    if [ "$open" = "y" ]; then vim "$destination"; fi
    if [[ "$backlog" = "y" ]]; then bck "$destination"; fi

}

gitPush() {
    repo_path=$1
    cd "$repo_path" || return
    git add "$destination"
    commit_deleted
    git commit -m "$destination" && git push
}
