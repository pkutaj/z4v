function get-Locations ([string]$filename, [string]$link, [string]$githubURL, [switch]$slog, [switch]$kb) {
    if ($slog) {
        $filename = Split-Path $filename -Leaf
        $githubURL = "https://github.com/pkutaj/slog/blob/master/_posts/$filename"
        $link = ".\$filename"
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
    git add $destination && git commit -m "$destination" && git push
}

function insert-extractedConcept([string]$insertUsecase, [string]$insertSteps) {
    if ($insertUsecase) {
        $findUsecase = "The aim(.*\n)+?(?=<)"
        $insertUsecase += "`n`n"
        (Get-Content -Path $destination -Raw) -replace $findUsecase, $insertUsecase | Set-Content $destination
    }
    if ($insertSteps) {
        $findSteps = "### 1. notes"
        $insertSteps = "$&`n$insertSteps`n"
        $template = (Get-Content -Path $destination -Raw)
        if(-not(Select-String $findSteps -inputObject $template)) {
            write-host $template
            throw "Cannot Extract Concepts - Dwarves believe you changed the docTemplate"
        }
        $template -replace $findSteps, $insertSteps | Set-Content $destination
    }
}

function new-slog {
    param (
        [string]$genre
    )
    $t = (Get-Content -path $t -Raw) -replace "<date>", $today.Substring(5)
    $t = $t -replace "<estimate>", $genre[0]
    $genre = $genre.ToUpper()
    $kb = "C:\Users\Admin\Documents\workspace\SNOW\SNOW-logs\_posts" 
    $destination = "$kb\$today-$genre-$filename"
    $githubURL = "https://github.com/pkutaj/slog/blob/master/_posts/$today-$genre-$filename"
    $link = ".\$today-$genre-$filename"
    Set-Content $t -Path $destination
    #gitPush
    if ($extract) { insert-extractedConcept -insertUsecase $extract }
    if ($url) {(Get-Content $destination) -replace "### 2. links", "$&`n* $url" | Set-Content $destination}
    if (!$silent) { Invoke-Item $destination }
    get-Locations -filename $filename -link $link -githubURL $githubURL
}

function new-wlog {
    $kb = "c:\Users\Admin\Documents\workspace\work.log\kb\" 
    $destination = "$kb\$cat\$today-$filename"
    $githubURL = "https://github.com/pkutaj/kb/blob/master/$cat/$today-$filename"
    $link = "..\$cat\$today-$filename"
    Get-Content $t | Set-Content $destination
    (Get-Content $destination) -replace "title:", "$& $name" | Set-Content $destination
    (Get-Content $destination) -replace "categories:", "$& [$cat]" | Set-Content $destination
    Write-Host "[~~~ new doc ~~~]" -ForegroundColor Cyan
    gitPush
    if ($extract) { insert-extractedConcept -insertSteps $extract }
    if ($url) {(Get-Content $destination) -replace "### 2. links", "$&`n* $url" | Set-Content $destination}
    if (!$silent) { Invoke-Item $destination }
    get-Locations -filename $filename -link $link -githubURL $githubURL
}

function New-Kba {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$kbType,
        [Parameter(Mandatory = $true)][string]$name,
        [Parameter(Mandatory = $true)][string]$cat,
        [Parameter(Mandatory = $false)][switch]$silent,
        [Parameter(Mandatory = $false)][string]$extract,
        [Parameter(Mandatory = $false)][string]$url
    )

    begin {
        $today = Get-Date -Format "yyyy-MM-dd"
        $invalidCharacters = "[^-A-Za-z0-9_\.]"
        $filename = ("$name" -replace $invalidCharacters, "-") -replace ".+", "$&.md"
        $t = "c:\Users\Admin\Documents\workspace\work.log\kb\personalKBTemplate.md"
        
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