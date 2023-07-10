function Lock-Device {
    $KPID_pw = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object {$_.KeyProtectorType -eq "RecoveryPassword"}
    $KPID_tpm = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object {$_.KeyProtectorType -eq "Tpm"}
    try {
        if($KPID_pw.KeyProtectorId -ne $null){
            foreach($kpid in $KPID_pw){
                Remove-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $kpid.KeyProtectorId -Confirm:$false | Out-Null
            }
            Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector
            $KPID = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object {$_.KeyProtectorType -eq "RecoveryPassword"}
            if($kpid -ne $null){
                BackupToAAD-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $KPID.KeyProtectorId -Confirm:$false | Out-Null
                cmd.exe /C "manage-bde -protectors -enable C:"
                cmd.exe /C "manage-bde -forcerecovery C:"
                Write-Error "Device locked successfully"
                shutdown -s -t 15 -f
                exit 0
            }
        } else {
            Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector 
            $KPID = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object {$_.KeyProtectorType -eq "RecoveryPassword"} | Out-Null
            if($KPID.KeyProtectorId -ne $null){
                BackupToAAD-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $KPID.KeyProtectorId -Confirm:$false | Out-Null
                cmd.exe /C "manage-bde -protectors -enable C:"
                cmd.exe /C "manage-bde -forcerecovery C:"
                Write-Error "Device locked successfully"
                shutdown -s -t 15 -f
                exit 0
            }
        }
        $latest = Get-ChildItem -Path "C:\Temp" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Add-Content -Path $latest.FullName -Value "Done"
    } catch {
        Write-Output "Failed to lock the device"
        exit 1
    }
}

Lock-Device
