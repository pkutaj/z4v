function get-Locations ([string]$filename, [string]$link, [string]$githubURL, [switch]$slog, [switch]$kb) {
    if ($slog) {
        #$filename = Split-Path $filename -Leaf
        $githubURL = "https://github.com/pkutaj/slog/blob/master/_posts/$filename"
        $link = "file:\\${filename}"
    }
    if ($kb) {
        $cat = Split-Path -Leaf (Split-Path $filename -Parent)
        $filename = Split-Path $filename -Leaf
        $githubURL = "https://github.com/pkutaj/kb/blob/master/$cat/$filename"
        $link = ".\$filename"
        <#
    .SYNOPSIS
        Pass a filepath, get Github + relative path markdown links
    .DESCRIPTION
        -slog       ~~> for slog linker
        kb       ~~> for KB linker
    #>
    }

    $locations = @"
* [GH: $filename][#1]
[#1]: $githubURL
* [local: $filename][#2]
[#2]: $link
"@
    $locations | Set-Clipboard
    Write-Host "clipping ~~~>" -ForegroundColor DarkCyan 
    return $locations
}

function gitPush() {
    cd $kb
    $FileStream = [System.IO.File]::Open("${destination}", 'Open', 'Write')
    $FileStream.Close()
    $FileStream.Dispose()    
    git add $destination 
    git ls-files --deleted | % { git add $_ }
    git commit -m "$destination" && git push
}

function insert-extractedConcept([string]$insertSteps) {   
    $findSteps = ">"
    $insertSteps = "$&`n$insertSteps"
    $template = (Get-Content -Path $destination -Raw)
    if (-not(Select-String $findSteps -InputObject $template)) {
        Write-Host $template
        throw "Cannot Extract Concepts - Dwarves believe you changed the docTemplate"
    }
    $template -replace $findSteps, $insertSteps | Set-Content $destination
}

function new-slog {
    param (
        [string]$genre
    )
    $genre = $genre.ToUpper()
    $kb = "C:\Users\Admin\Documents\workspace\SNOW\SNOW-logs\_posts" 
    $full_slog_name = "$genre-$points-$today-$filename"
    $destination = "$kb\$full_slog_name"
    $githubURL = "https://github.com/pkutaj/slog/blob/master/_posts/$full_slog_name"
    $link = ".\$full_slog_name"
    Set-Content $t -Path $destination
    # gitPush
    if ($extract) { insert-extractedConcept -insertSteps $extract }
    if ($url) { (Get-Content $destination) -replace "## LINKS", "$&`n$url" | Set-Content $destination }
    if ($open?) { code $destination }
    get-Locations -filename $filename -link $link -githubURL $githubURL
}

function new-wlog {
    $kb = "c:\Users\Admin\Documents\workspace\work.log\kb\" 
    $destination = "$kb\$cat\$today-$filename"
    $githubURL = "https://github.com/pkutaj/kb/blob/master/$cat/$today-$filename"
    $link = "..\$cat\$today-$filename"
    Set-Content $t -Path $destination
    (Get-Content $destination) -replace "title:", "$& $name" | Set-Content $destination
    (Get-Content $destination) -replace "categories:", "$& [$cat]" | Set-Content $destination
    Write-Host "[~~~ new doc ~~~]" -ForegroundColor Cyan
    if ($extract) { insert-extractedConcept -insertSteps $extract }
    if ($url) { (Get-Content $destination) -replace "## LINKS", "$&`n* $url" | Set-Content $destination }
    if ($open?) { code $destination }
    gitPush
    get-Locations -filename $filename -link $link -githubURL $githubURL
}

function New-Kba {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$kbType,
        [Parameter(Mandatory = $true)][string]$name,
        [Parameter(Mandatory = $true)][string]$cat,
        [Parameter(Mandatory = $true)][bool]$open?,
        [Parameter(Mandatory = $true)]$url,
        [Parameter(Mandatory = $true)]$extract
    )

    begin {
        $today = Get-Date -Format "yyyy-MM-dd"
        $invalidCharacters = "[^-A-Za-z0-9_\.]"
        $filename = (("$name" -replace " - Jira", "") -replace $invalidCharacters, "-") -replace ".+", "$&.md"
        $t = "${env:Z4V_FOLDER}\page_template.md"
        $t = (Get-Content -Path $t -Raw) -replace "<date>", $today.Substring(5)
        
    }
    process {
        switch ($kbType) {
            "k" {
                new-wlog
            }
            "s" {
                try {
                    new-slog -genre $cat
                }
                catch {
                    Write-Host "ERROR" -ForegroundColor Magenta
                    Write-Host "~~> $_"  -ForegroundColor Magenta
                }
                
            } 
        }
       
    }
    end {
        
    }
    <#
.SYNOPSIS
    The concern is to have a utility that automates the template creation.
    A - alert
    F - fucking bullshit
    U - upgrades
    T - tickets
    OK - OK(R) thingies
    DOC - docsy
    
#>
}
