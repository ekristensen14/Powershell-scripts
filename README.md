# Powershell-scripts
Collection of my Powershell scripts.


# Lock-Windows
Rotates the bitlocker recovery password, then forces the device into recovery and then shuts down.
Use with the "Remediations" in Microsoft Intune.
1. Upload the Detection-Lock-Windows.ps1 as the detection script.
2. Upload the Remediation-Lock-Windows.ps1 as the remediation script.
3. Run script using the logged-on credentials: No
4. Enforce script signature check: No
5. Run script in 64-bit Powershell: Yes
6. Don't include any devices.
7. To run the script, go into the device you want to lock, press 3 dots (...), on the top right. Then press "Run remediation (preview)" then select your remediation profile.
8. The device will rotate the bitlocker key and save it to AAD/Intune then go into recoverymode by removing the TPM key and then shutdown.
