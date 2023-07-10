function Check-IfRemediationRan {
    $generatehash = New-Guid
    $NewFile = "C:\Temp\$($generatehash)-00"
    if(Test-Path $NewFile){
        exit 0
    } else {
        exit 1
    }
}
Check-IfRemediationRan
