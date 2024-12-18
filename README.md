# Export All Microsoft 365 Users MFA Status(Enable/Enforced/Disabled) Report 🚀
In Microsoft 365, checking the Multi-Factor Authentication (MFA) status per user is possible via the Microsoft Entra admin center. However, it doesn’t provide detailed information. To get a detailed list of all users' MFA statuses in a single CSV file, you can use a PowerShell script.

This guide will walk you through how to **export all Microsoft 365 users' MFA status** to a CSV file using PowerShell.

## Table of Contents 📑

- [Install Microsoft Graph PowerShell](#install-microsoft-graph-powershell)
- [Download MFA Status PowerShell Script](#download-mfa-status-powershell-script)
- [Export MFA Status Report to CSV](#export-mfa-status-report-to-csv)
- [Microsoft MFA Authentication Methods](#microsoft-mfa-authentication-methods)
- [Conclusion](#conclusion)

---

## Install Microsoft Graph PowerShell ⚙️

Before running the script, you need to install the **Microsoft Graph PowerShell module**.

1. **Run PowerShell as Administrator**.
2. Execute the following commands to install the required modules:

```powershell
Install-Module Microsoft.Graph -Force
```

```powershell
Install-Module Microsoft.Graph.Beta -AllowClobber -Force
```

> **Important:** Always install the Microsoft Graph PowerShell and Microsoft Graph Beta PowerShell modules. Some cmdlets may only be available in the Beta version. Always update both modules to avoid errors.

---

## Get MFA Status(Enable/Enforced/Disabled) PowerShell Script 📥

You can either **download** the `Get-MFAReport.ps1` script or **create** it manually.

### Option 1: Download Script
- (Save it in the `C:\Users\Administrator\Desktop\scripts` folder).

### Option 2: Create the Script Manually
1. Open **Notepad**.
2. Copy and paste the following code:

```powershell
<#
    .SYNOPSIS
    Get-MFAReport.ps1

    .DESCRIPTION
    Export Microsoft 365 per-user MFA report with Micrososoft Graph PowerShell.

    .LINK
    www.alitajran.com/export-office-365-users-mfa-status-with-powershell/

    .NOTES
    Written by: ALI TAJRAN
    Website:    www.alitajran.com
    LinkedIn:   linkedin.com/in/alitajran

    .CHANGELOG
    V1.00, 04/04/2021 - Initial version
    V2.00, 08/04/2024 - Rewritten for Microsoft Graph PowerShell
#>

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "User.Read.All", "Policy.ReadWrite.AuthenticationMethod", "UserAuthenticationMethod.Read.All"

# CSV export file path
$CSVfile = "C:\temp\MFAUsers.csv"

# Get properties
$Properties = @(
    'Id',
    'DisplayName',
    'UserPrincipalName',
    'UserType',
    'Mail',
    'ProxyAddresses',
    'AccountEnabled',
    'CreatedDateTime'
)

# Get all users
[array]$Users = Get-MgUser -All -Property $Properties | Select-Object $Properties

# Initialize the report list
$Report = [System.Collections.Generic.List[Object]]::new()

# Check if any users were retrieved
if (-not $Users) {
    Write-Host "No users found. Exiting script." -ForegroundColor Red
    return
}

# Initialize progress counter
$counter = 0
$totalUsers = $Users.Count

# Loop through each user and get their MFA settings
foreach ($User in $Users) {
    $counter++

    # Calculate percentage completion
    $percentComplete = [math]::Round(($counter / $totalUsers) * 100)

    # Define progress bar parameters with user principal name
    $progressParams = @{
        Activity        = "Processing Users"
        Status          = "User $($counter) of $totalUsers - $($User.UserPrincipalName) - $percentComplete% Complete"
        PercentComplete = $percentComplete
    }

    Write-Progress @progressParams

    # Get MFA settings
    $MFAStateUri = "https://graph.microsoft.com/beta/users/$($User.Id)/authentication/requirements"
    $Data = Invoke-MgGraphRequest -Uri $MFAStateUri -Method GET

    # Get the default MFA method
    $DefaultMFAUri = "https://graph.microsoft.com/beta/users/$($User.Id)/authentication/signInPreferences"
    $DefaultMFAMethod = Invoke-MgGraphRequest -Uri $DefaultMFAUri -Method GET

    # Determine the MFA default method
    if ($DefaultMFAMethod.userPreferredMethodForSecondaryAuthentication) {
        $MFAMethod = $DefaultMFAMethod.userPreferredMethodForSecondaryAuthentication
        Switch ($MFAMethod) {
            "push" { $MFAMethod = "Microsoft authenticator app" }
            "oath" { $MFAMethod = "Authenticator app or hardware token" }
            "voiceMobile" { $MFAMethod = "Mobile phone" }
            "voiceAlternateMobile" { $MFAMethod = "Alternate mobile phone" }
            "voiceOffice" { $MFAMethod = "Office phone" }
            "sms" { $MFAMethod = "SMS" }
            Default { $MFAMethod = "Unknown method" }
        }
    }
    else {
        $MFAMethod = "Not Enabled"
    }

    # Filter only the aliases
    $Aliases = ($User.ProxyAddresses | Where-Object { $_ -clike "smtp*" } | ForEach-Object { $_ -replace "smtp:", "" }) -join ', '

    # Create a report line for each user
    $ReportLine = [PSCustomObject][ordered]@{
        UserPrincipalName = $User.UserPrincipalName
        DisplayName       = $User.DisplayName
        MFAState          = $Data.PerUserMfaState
        MFADefaultMethod  = $MFAMethod
        PrimarySMTP       = $User.Mail
        Aliases           = $Aliases
        UserType          = $User.UserType
        AccountEnabled    = $User.AccountEnabled
        CreatedDateTime   = $User.CreatedDateTime
    }
    $Report.Add($ReportLine)
}

# Complete the progress bar
Write-Progress -Activity "Processing Users" -Completed

# Display the report in a grid view
$Report | Out-GridView -Title "Microsoft 365 per-user MFA Report"

# Export the report to a CSV file
$Report | Export-Csv -Path $CSVfile -NoTypeInformation -Encoding utf8
Write-Host "Microsoft 365 per-user MFA Report is in $CSVfile" -ForegroundColor Cyan
```

3. **Save** the file as `Get-MFAReport.ps1` in the `C:\Users\Administrator\Desktop\scripts` folder.

---

## Export MFA Status Report to CSV 💾

### Before Running the Script:
1. Create a folder named `temp` inside your **Local Disk(C)** (C:\temp).
 **Note: This is inside the (This Pc\Local Disk(C)\temp)**
2. Ensure you have the `Get-MFAReport.ps1` script saved in the `C:\Users\Administrator\Desktop\scripts` folder.

### Run the Get-MFAReport PowerShell Script:
1. **Open PowerShell as Administrator**.
2. Run the script:

```powershell
C:\Users\Administrator\Desktop\scripts\Get-MFAReport.ps1
```

3. When prompted, **sign in** using your Microsoft admin credentials.  
   - Enter your password
   - Click **Sign in**
   
4. **Grant consent** for the necessary permissions:
   - **Enable Consent on behalf of your organization**
   - Click **Accept**

### Progress Bar:
The PowerShell script will show a progress bar and notify you when it's finished.

- **Example Output:**

```
Script completed. Results exported to C:\temp\MFAUsers.csv
```

## Open MFA Users report CSV file 💾

The **Get-MFAReport.ps1** PowerShell script will export Office 365 users MFA status to CSV file. Find the file MFAUsers.csv in the path C:\temp.
**(Note: This Pc\Local Disk (c)\Temp)**

The CSV file name is seen as **MFAUsers.csv** 


> You can find the CSV file in the `C:\temp` folder. Open it using **Microsoft Excel** or any CSV viewer to review the results.

---

## Microsoft MFA Authentication Methods 🔑

The script checks for the following MFA methods for each user:

| Authentication Method  | Description                                                  |
|------------------------|--------------------------------------------------------------|
| **Email**               | Use email for Self-Service Password Reset (SSPR).            |
| **Fido2**               | Use FIDO2 Security Key for sign-in to Microsoft Entra ID.    |
| **Microsoft Authenticator** | Use Microsoft Authenticator for MFA.                    |
| **Phone**               | Use SMS or voice call for authentication.                    |
| **SoftwareOath**        | Use Microsoft Authenticator or OATH token for MFA.           |
| **TemporaryAccessPass** | A time-limited passcode for onboarding passwordless sign-in.|
| **WindowsHelloForBusiness** | Passwordless sign-in on Windows devices.              |

---

## Conclusion 🎯

You’ve successfully learned how to export all Microsoft 365 users' MFA status to a CSV file. By using the **Microsoft Graph PowerShell module**, the `Get-MFAReport.ps1` script provides an efficient way to gather this information in a structured manner. This report helps you see which users have MFA enabled and which authentication methods they use.

**Next Steps**:  
- Review users with **MFA disabled** and encourage them to enable MFA for enhanced security.

  **The End**
