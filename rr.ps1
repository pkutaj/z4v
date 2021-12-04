function rename ($old_name, $new_name) {
    Rename-Item -Path $old_name -NewName $new_name -Verbose -Force
}
function relink($old_name, $new_name) {
    (dir *.md -Recurse).FullName | ForEach-Object {
        (Get-Content -Path $_ -Raw) -replace "$old_name", "$new_name" |
            Set-Content -Path $_ -NoNewline }
}

function rr {
    param (
        [Parameter(Position = 0, Mandatory = $True)][string]$old_full_path,
        [string]$new_name,
        [Parameter(Mandatory = $True, ParameterSetName = "slog")][switch]$kb,
        [Parameter(Mandatory = $True, ParameterSetName = "kb")][switch]$slog,
        [switch]$only_timestamp_update
    )
    function _update_timestamp_only {
        $timestamp_regex = '\d{4}-\d{2}-\d{2}'
        $new_name = $old_name -replace $timestamp_regex, $today
        return $new_name
    }
    function _compose_brand_new_name {
        $new_name = Read-Host "new_name" 
        $new_name = ("$new_name" -replace $all_except_char_regex, "-") -replace ".+", "$&.md"
        $new_name = "$today-$new_name"
        return $new_name
    }

    $today = Get-Date -Format "yyyy-MM-dd"
    $old_name = Split-Path $old_full_path -Leaf
    $all_except_char_regex = "[^-A-Za-z0-9_\.]"
    if ($only_timestamp_update) { $new_name = _update_timestamp_only } 
    else { $new_name = _compose_brand_new_name }
    
    if ($kb) { $pages_folder = (Split-Path $old_full_path -Parent) }
    if ($slog) { $pages_folder = $env:SLOGFOLDER }
    cd $pages_folder
    
    relink $old_name $new_name
    rename $old_name $new_name
    push-assets "..\assets" *> $null
    Invoke-Item $new_name
    Write-Host "Z4V Dwarves Salute! Relinking Done" -ForegroundColor DarkGreen

}

# rr "C:\Users\Admin\Documents\workspace\work.log\kb\productivity\2021-05-20-Reference-Links-in-Markdown.md" -kb -only_timestamp_update