function Check-IfRemediationRan {
    $generatehash = New-Guid
    $NewFile = "C:\Temp\$($generatehash).txt"
    if(Test-Path $NewFile){
        exit 0
    } else {
        exit 1
    }
}
Check-IfRemediationRan
