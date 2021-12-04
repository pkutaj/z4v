function transform-for-medium($tempDoc) {
    (Get-Content -Path $tempDoc -Raw) -replace "## usecase", "" | Set-Content $tempDoc
    (Get-Content -Path $tempDoc -Raw) -replace "\n<!-- TOC -->.*\n(.*\n){1,}<!-- /TOC -->.*\n", "" | Set-Content $tempDoc
}

function pub-git {
    param(
        [string]$wlogPath, 
        [string]$docName)
    git add $wlogPath
    git add "..\assets"
    git add "..\"
    git commit -a -m "$docName"
    git push
    Write-Host "~~~ the result of the git push ~~~" -ForegroundColor cyan
    git log --pretty=format:"%h%x09%an%x09%ad%x09%s" --name-status --date=short -1 
    Write-Host "~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~" -ForegroundColor cyan
}

function pub-medium ($docName, $docPath) {
    $docFolder = Split-Path $docPath -Parent
    $TextInfo = (Get-Culture).TextInfo
    $docTitle = ((($docName -replace "\d", "") -replace "-", " ") -replace "\.md", "") -replace "\s{2,}", ""
    $docTitle = $TextInfo.ToTitleCase($docTitle)
    $docKbFolder = Split-Path -Leaf (Split-Path $docPath -Parent)
    $tempDoc = "temp_$docName"
    $tempDocPath = "$docFolder\\$tempDoc"
    $pyscript = $env:pyscript
    $cert = $env:cacert
    pushd $docFolder
    Copy-Item $cert -Destination $docFolder -Force
    Copy-Item -Path $pyscript -Destination $docFolder -Force
    Copy-Item -Path $docName -Destination $tempDoc
    transform-for-medium($tempDoc)
    $arg1 = "$docFolder\md2med.py"
    $arg2 = "--doc_name=$docTitle" 
    $arg3 = "--file_to_publish=$tempDocPath"
    $arg4 = "--tag=$docKbFolder"
    python $arg1 $arg2 $arg3 $arg4
    Remove-Item "./cacert.pem" -Force
    Remove-Item $arg1
    Remove-Item $tempDoc
    popd
    start chrome "https://pavolkutaj.medium.com"
}

function pub-wlog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$docPath
    )
    
    begin {
        Set-Location (Split-Path -Parent $docPath)
        $today = (Get-Date).toString("yyyy-MM-dd")
        $docFileName = Split-Path -Leaf $docPath 
        $docName = ($docName -match "\d\d\.\d\d") ? $docFileName -replace "\d\d.\d\d", $today : $docFileName
        if ($docFileName -match "\d\d\.\d\d") {Rename-Item $docPath $docName}
        $pubMediumScript = $env:md2med_SCRIPT
        $mediaList = "c:\Users\Admin\Documents\workspace\work.log\pkutaj\playlist.md"
        $wlogFolder = "c:\Users\Admin\Documents\workspace\work.log\pkutaj\_posts\"    
        $cv = "c:\Users\Admin\Documents\workspace\work.log\pkutaj\index.markdown"
        $wlogPath = "$wlogFolder\$docName"
        $wlogAssets = "c:\Users\Admin\Documents\workspace\work.log\pkutaj\assets\"
        $replace = "../assets/"
        $replaceWith = "{{ site.url }}/assets/"
        $text = gc $docPath -raw 
        $r = "\.\.\/assets\/img.*(?=\))" #lookahead to match all until ')'
    }
    
    process {
        If (Read-Host "Publish to Medium? (y/Enter)") { pub-medium $docName $docPath } 
        If (Read-Host "Modify mediaList? (y/Enter)") { Invoke-Item $mediaList }
        If (Read-Host "Modify CV? (y/Enter)") { Invoke-Item $cv }
        if ($docName -match "\d\d\.\d\d") {
            $newName = $docName -replace "\d\d.\d\d", $today
            Rename-Item $docname, $newName
        }
        
    <#     try {
            ($text | 
                Select-String $r -AllMatches).Matches.Value |
                ForEach-Object { Copy-Item $_ $wlogAssets -Verbose -Force }
        }
 
        catch {
            Write-Host "~~~ No images found ~~~" -ForegroundColor DarkMagenta
        }
        
        (Get-Content $docPath).replace($replace, $replaceWith) |
            Set-Content $wlogPath
         #>
            
        pushd $wlogFolder
        pub-git -wlogPath $wlogPath -docName $docName
        
    }
    
    end {
        popd
    }
}