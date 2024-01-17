# Set variables
$clientID=""
$secretValue=""
$tenantID=""

# Generate access token
$url = "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token"
$data = @{
    client_id = $clientID
    scope = "https://graph.microsoft.com/.default"
    client_secret = $secretValue
    grant_type = "client_credentials"
}
$response = Invoke-RestMethod -Uri $url -Method Post -Body $data
$token = $response.access_token

# Create logdir if it doesn't exist
$logdir = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DeviceRename"
if (!(Test-Path $logdir)) {
    Write-Output "$(Get-Date) | Creating log directory $logdir"
    New-Item -Path $logdir -ItemType Directory
} else {
    Write-Output "$(Get-Date) | Log directory $logdir already exists"
}

# Start logging
$logfile = "$logdir\DeviceRename.log"
Write-Output "$(Get-Date) | Logging to $logfile"
Start-Transcript -Path $logfile -Append

# Get device name
$deviceName = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
Write-Output "$(Get-Date) | Device name is currently $deviceName"

# Get logged in UPN
$UPN = whoami /upn

# Get user display name from Entra
$graphUrl = "https://graph.microsoft.com/v1.0/users/$UPN/?`$select=displayName"
$headers2 = @{
    Authorization = "Bearer $token"
}
Write-Output "$(Get-Date) | getting the display name"

# Get displayname and select only first and last name
$response = Invoke-RestMethod -Uri $graphUrl -Headers $headers2
$fullname = $response.displayName -split ' ' | ForEach-Object { $_.Trim() }
$firstname = $fullname[0]
$lastname = $fullname[-1]

# Generate the new device name, limiting at 15 characters. Starting with "p44-" and adding the first initial and last name all in lowercase
$newDeviceName = "p44-$($firstname.Substring(0,1))$($lastname.Substring(0,[Math]::Min(14, $lastname.Length)))"
# Set newDeviceName to lowercase
$newDeviceName = $newDeviceName.ToLower()

# Get the current device name
$currentDeviceName = (Get-CimInstance -Class Win32_ComputerSystem).Name

# Check if the device name already begins with p44-
if ($currentDeviceName -like "p44-*" -or $currentDeviceName -like "P44-*" -or $currentDeviceName -like "CPC-*") {
    Write-Output "$(Get-Date) | Device name already begins with p44- or CPC- (if cloud PC)"
    Write-Output "$(Get-Date) |  + Current Device Name: $currentDeviceName"
    Write-Output "$(Get-Date) |  + New Device Name: $newDeviceName"
    Write-Output "$(Get-Date) |  + Exiting"
    exit 0
} else {
    try{
        Write-Output "$(Get-Date) | Device name does not begin with p44-"
        Write-Output "$(Get-Date) |  + Current Device Name: $currentDeviceName"
        Write-Output "$(Get-Date) |  + New Device Name: $newDeviceName"
        # Check if the new device name is already in use in Intune
        Write-Output "$(Get-Date) | Checking if the new device name is already in use in Intune"
        $filter = "`$filter=devicename eq '$newDeviceName'"
        $deviceNameInUse = (Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/?$filter" -Headers $headers2 | Select-Object -ExpandProperty value | Select-String -Pattern $newDeviceName -AllMatches).Matches.Count
        # If the device name is already in use, add a number starting from 2 to the end of the device name
        if ($deviceNameInUse -gt 0) {
            Write-Output "$(Get-Date) | Device name is already in use in Intune"
            Write-Output "$(Get-Date) |  + Adding a number to the end of the device name"
            # Set the number to 2
            $number = 2
            # Loop until the device name is not in use
            while ($deviceNameInUse -gt 0) {
                # Add the number to the end of the device name
                $newDeviceName = "$newDeviceName$number"
                # Check if the new device name is already in use in Intune
                $deviceNameInUse = (Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/?$filter" -Headers $headers2 | Select-Object -ExpandProperty value | Select-String -Pattern $newDeviceName -AllMatches).Matches.Count
                # Increment the number
                $number++
            }
            Write-Output "$(Get-Date) |  + New Device Name: $newDeviceName"
        }
    
        # Set the new device name
        Rename-Computer -NewName $newDeviceName -Force
        Write-Output "$(Get-Date) |  + Device name changed"
        Write-Output "$(Get-Date) |  + Exiting"
        
        # Notify the user that the device name has been changed
        $title = "Device Name Change"
        $message = "Your device name has been changed to $newDeviceName. Please restart your device to apply the change."
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup($message,0,$title,0x1)
        exit 0    
    } catch {
        Write-Output "$(Get-Date) | Error: $_"
        Write-Output "$(Get-Date) |  + Exiting"
        exit 1
    }
}
