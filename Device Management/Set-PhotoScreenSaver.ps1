### Download screensaver to C:\Custom
$DirectoryToCreate = "$env:SystemDrive\Custom\"
$screensaverImg = ""
New-PSDrive HKU Registry HKEY_USERS -ErrorAction SilentlyContinue | out-null
$users = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName
foreach($user in $users){
    $sid = (New-Object System.Security.Principal.NTAccount($user)).Translate([System.Security.Principal.SecurityIdentifier]).value;

    if (-not (Test-Path -LiteralPath $DirectoryToCreate)) {
        New-Item -Path $DirectoryToCreate -ItemType Directory -ErrorAction Stop | Out-Null #-Force
        Get-Item $DirectoryToCreate -Force | foreach { $_.Attributes = $_.Attributes -bor "Hidden" }
    }
    else {
        Get-Item $DirectoryToCreate -Force | foreach { $_.Attributes = $_.Attributes -bor "Hidden" }
    }
    
    try {
        Invoke-WebRequest -Uri $screensaverImg -OutFile "$DirectoryToCreate\screensaverimg1.jpg"
        Set-ItemProperty -Path "HKU:\$sid\Control Panel\Desktop" -Name ScreenSaveActive -Value 1
        Set-ItemProperty -Path "HKU:\$sid\Control Panel\Desktop" -Name ScreenSaveTimeOut -Value 600
        Set-ItemProperty -Path "HKU:\$sid\Control Panel\Desktop" -Name scrnsave.exe -Value "$env:SystemRoot\system32\PhotoScreensaver.scr"
        $path = "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver"
        $checkPath = Test-Path $path
        if ($checkPath -eq $true) {
            Set-ItemProperty -Path "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name EncryptedPIDL -Value "FAAfUOBP0CDqOmkQotgIACswMJ0ZAC9DOlwAAAAAAAAAAAAAAAAAAAAAAAAAVAAxAAAAAABSV+tJEgBDdXN0b20AAD4ACQAEAO++UlejSVJX60kuAAAAgH4DAAAAIwAAAAAAAAAAAAAAAAAAAEtsXABDAHUAcwB0AG8AbQAAABYAAAA=" -Force | Out-Null
            Set-ItemProperty -Path "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name Shuffle -Value 1 -Force | Out-Null
            Set-ItemProperty -Path "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name Speed -Value 0 -Force | Out-Null
            "OK"
            return
            
        }
        else {
            New-Item -Path "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Force | Out-Null
            New-ItemProperty -Path "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name EncryptedPIDL -Value "FAAfUOBP0CDqOmkQotgIACswMJ0ZAC9DOlwAAAAAAAAAAAAAAAAAAAAAAAAAVAAxAAAAAABSV+tJEgBDdXN0b20AAD4ACQAEAO++UlejSVJX60kuAAAAgH4DAAAAIwAAAAAAAAAAAAAAAAAAAEtsXABDAHUAcwB0AG8AbQAAABYAAAA=" -Force | Out-Null
            New-ItemProperty -Path "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name Shuffle -Value 1 -Force | Out-Null
            New-ItemProperty -Path "HKU:\$sid\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name Speed -Value 0 -Force | Out-Null
            "OK"
            return
            
        }
    }
    catch {
        "Error"
        exit 1
       
    }
}
exit 0
