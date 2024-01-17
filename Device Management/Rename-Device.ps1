$clientID=""
$secretValue=""
$tenantID=""
$logoUrl = ""

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
        
        # Notify the user that the device name has been changed. Include company logo in the popup
        $logo = $env:TEMP + "\logo.png"
        Invoke-WebRequest -Uri $logoUrl -OutFile $logo
        $title = "Device Name Changed"
        $message = "Your device name has been changed to $newDeviceName."
        $message4 = "Please restart your device to apply the change."
        $message2 = "Thank you for your cooperation."
        $message3 = "project44 IT Team"
        $message5 = "(Press Enter to close this window)"
        $combined = "$message`n`n$message4`n`n$message2`n`n$message3`n`n`n`n$message5"
        Add-Type -AssemblyName System.Windows.Forms
        $popup = New-Object System.Windows.Forms.Form
        $popup.Text = $title
        $popup.Width = 700
        $popup.Height = 300
        $popup.StartPosition = "CenterScreen"
        $popup.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
        $popup.Topmost = $true
        $popup.ShowInTaskbar = $false
        $popup.BackColor = "#ffffff"
        $popup.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point)
        $popup.ForeColor = "#000000"
        $popup.KeyPreview = $true
        
        $popup.Add_KeyDown({
            if ($_.KeyCode -eq "Enter") { 
                $popup.Close() 
            } 
        })
        
        $layoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
        $layoutPanel.RowCount = 1
        $layoutPanel.ColumnCount = 2
        $layoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $combined
        $label.AutoSize = $true
        $label.Anchor = [System.Windows.Forms.AnchorStyles]::Left
        $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        
        $pictureBox = New-Object System.Windows.Forms.PictureBox
        $pictureBox.Image = [System.Drawing.Image]::FromFile($logo)
        $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $pictureBox.Anchor = [System.Windows.Forms.AnchorStyles]::Right
        
        $layoutPanel.Controls.Add($label, 0, 0)
        $layoutPanel.Controls.Add($pictureBox, 1, 0)
        
        $popup.Controls.Add($layoutPanel)
        $popup.ShowDialog()

        $dialogResult = [System.Windows.Forms.MessageBox]::Show("Do you want to restart now?", "Restart", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question, [System.Windows.Forms.MessageBoxDefaultButton]::Button2)
        if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            Restart-Computer -Force
        }else {
            Write-Output "$(Get-Date) | User chose not to restart"
            exit 0    
        }
    } catch {
        Write-Output "$(Get-Date) | Error: $_"
        Write-Output "$(Get-Date) |  + Exiting"
        exit 1
    }
}
