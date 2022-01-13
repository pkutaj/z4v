function transform-for-medium($tempDoc) {
    (Get-Content -Path $tempDoc -Raw) -replace "## usecase", "" | Set-Content $tempDoc
    (Get-Content -Path $tempDoc -Raw) -replace "\n<!-- TOC -->.*\n(.*\n){1,}<!-- /TOC -->.*\n", "" | Set-Content $tempDoc
}

function pub-git {
    git add "."
    git add ".\assets"
    git commit -a -m $today
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
        $wlogFolder = "c:\Users\Admin\Documents\workspace\work.log\pkutaj\"    
        $cv = "c:\Users\Admin\Documents\workspace\work.log\pkutaj\index.markdown"
        $cv_pdf = "c:\Users\Admin\Documents\familia\doklady\40-49 mrp\Pavol-Kutaj-Resume.pdf"
        $wlogPath = "$wlogFolder\$docName"
        
    }
    
    process {
        If (Read-Host "Publish to Medium? (y/Enter)") { pub-medium $docName $docPath } 
        If (Read-Host "Modify mediaList? (y/Enter)") { Invoke-Item $mediaList }
        If (Read-Host "Modify CV? (y/Enter)") { 
            Invoke-Item $cv 
            Pause
            create-pdf-from-md -source_file $cv -target_file $cv_pdf}
        pushd $wlogFolder
        pub-git
    }
    
    end {
        popd
    }
}