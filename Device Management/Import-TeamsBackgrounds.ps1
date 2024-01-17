$TeamsBackGroundURL = ""
$TeamsBackgroundZipPath = $env:TEMP+"\Teamsbackgrounds2.zip"
try{
    Invoke-WebRequest -Uri $TeamsBackGroundURL -OutFile $TeamsBackgroundZipPath
} catch {
    Write-Output "Error: $($_.Exception.Message)"
    exit 1
}

$users = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {$_.LocalPath -like "*\Users\*" -and $_.LocalPath -notlike "*\Users\Public"} | select LocalPath

$global:ErrorMessage = @()

foreach($user in $users){
    $TeamsBackgroundBasePath = "$($user.LocalPath)\AppData\Roaming\Microsoft\Teams\Backgrounds\"
    $TeamsBackgroundUploadPath = $TeamsBackgroundBasePath+"Uploads"
    if(-not (Test-Path $TeamsBackgroundUploadPath)){
        try{         
            "No Teams Classic Backgrounds Folder"
        } catch {
            $global:ErrorMessage += "Error: $($_.Exception.Message)"
        }
    
    } else{
        try {
            ### Clear folder
            Get-ChildItem -Path $TeamsBackgroundUploadPath -Recurse | Remove-Item -Force -Recurse
            Expand-Archive -Path $TeamsBackgroundZipPath -DestinationPath $TeamsBackgroundUploadPath -Force
            "OK"
        } catch {
            $global:ErrorMessage += "Error: $($_.Exception.Message)"
        }
    }
    $NewTeamsBackgroundBasePath = "$($user.LocalPath)\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\"
    $NewTeamsBackgroundUploadPath = $NewTeamsBackgroundBasePath+"Uploads"

    if(-not (Test-Path $NewTeamsBackgroundUploadPath)){
        try {
            "No New Teams Backgrounds Folder"
        } catch {
            $global:ErrorMessage += "Error: $($_.Exception.Message)"
        }
    } else{
        try {
            ### Clear folder
            Get-ChildItem -Path $NewTeamsBackgroundUploadPath -Recurse | Remove-Item -Force -Recurse
            Expand-Archive -Path $TeamsBackgroundZipPath -DestinationPath $NewTeamsBackgroundUploadPath -Force
            "OK"
        } catch {
            $global:ErrorMessage += "Error: $($_.Exception.Message)"
        }
    }
}
### Remove the zip file
Remove-Item -Path $TeamsBackgroundZipPath -Force

if($global:ErrorMessage -ne $null -and $global:ErrorMessage -ne ""){
    $global:ErrorMessage | Out-File -FilePath $env:TEMP"\TeamsBackgrounds.log"
    Write-Output $global:ErrorMessage
    exit 1
} else {
    exit 0
}
