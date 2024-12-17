# Export All Microsoft 365 Users MFA Status Report 🚀
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
Install-Module Microsoft.Graph.Beta -AllowClobber -Force
```

> **Important:** Always install the Microsoft Graph PowerShell and Microsoft Graph Beta PowerShell modules. Some cmdlets may only be available in the Beta version. Always update both modules to avoid errors.

---

## Download MFA Status PowerShell Script 📥

You can either **download** the `Export-MFAstatus.ps1` script or **create** it manually.

### Option 1: Download Script
- [Download the script](#) (Save it in the `C:\Users\Administrator\Desktop\scripts` folder).

### Option 2: Create the Script Manually
1. Open **Notepad**.
2. Copy and paste the following code:

```powershell
# Connect to Microsoft Graph with necessary scopes
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All" -NoWelcome

# Create variable for the date stamp
$LogDate = Get-Date -f yyyyMMddhhmm

# Define CSV file export location variable
$Csvfile = "C:\temp\MFAUsers_$LogDate.csv"

# Get all Microsoft Entra ID users
$users = Get-MgUser -All

# Initialize a List to store the data
$Report = [System.Collections.Generic.List[Object]]::new()

# Initialize progress counter
$counter = 0
$totalUsers = $users.Count

# Loop through each user account
foreach ($user in $users) {
    $counter++

    # Calculate percentage completion
    $percentComplete = [math]::Round(($counter / $totalUsers) * 100)

    # Define progress bar parameters with user principal name
    $progressParams = @{
        Activity        = "Processing Users"
        Status          = "User $($counter) of $totalUsers - $($user.UserPrincipalName) - $percentComplete% Complete"
        PercentComplete = $percentComplete
    }

    Write-Progress @progressParams

    # Create an object to store user MFA information
    $ReportLine = [PSCustomObject]@{
        DisplayName               = "-"
        UserPrincipalName         = "-"
        MFAstatus                 = "Disabled"
        DefaultMFAMethod          = "-"
        Email                     = "-"
        Fido2                     = "-"
        MicrosoftAuthenticatorApp = "-"
        Phone                     = "-"
        SoftwareOath              = "-"
        TemporaryAccessPass       = "-"
        WindowsHelloForBusiness   = "-"
    }

    $ReportLine.UserPrincipalName = $user.UserPrincipalName
    $ReportLine.DisplayName = $user.DisplayName

    # Retrieve the default MFA method
    $DefaultMFAMethod = Get-MgBetaUserAuthenticationSignInPreference -UserId $user.Id
    if ($DefaultMFAMethod.userPreferredMethodForSecondaryAuthentication) {
        $ReportLine.DefaultMFAMethod = $DefaultMFAMethod.userPreferredMethodForSecondaryAuthentication
    }
    else {
        $ReportLine.DefaultMFAMethod = "Not set"
    }

    # Check authentication methods for each user
    $MFAData = Get-MgUserAuthenticationMethod -UserId $user.Id

    foreach ($method in $MFAData) {

        Switch ($method.AdditionalProperties["@odata.type"]) {
            "#microsoft.graph.emailAuthenticationMethod" {
                $ReportLine.Email = $true
                $ReportLine.MFAstatus = "Enabled"
            }
            "#microsoft.graph.fido2AuthenticationMethod" {
                $ReportLine.Fido2 = $true
                $ReportLine.MFAstatus = "Enabled"
            }
            "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                $ReportLine.MicrosoftAuthenticatorApp = $true
                $ReportLine.MFAstatus = "Enabled"
            }
            "#microsoft.graph.phoneAuthenticationMethod" {
                $ReportLine.Phone = $true
                $ReportLine.MFAstatus = "Enabled"
            }
            "#microsoft.graph.softwareOathAuthenticationMethod" {
                $ReportLine.SoftwareOath = $true
                $ReportLine.MFAstatus = "Enabled"
            }
            "#microsoft.graph.temporaryAccessPassAuthenticationMethod" {
                $ReportLine.TemporaryAccessPass = $true
                $ReportLine.MFAstatus = "Enabled"
            }
            "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" {
                $ReportLine.WindowsHelloForBusiness = $true
                $ReportLine.MFAstatus = "Enabled"
            }
        }
    }
    # Add the report line to the List
    $Report.Add($ReportLine)
}

# Clear progress bar
Write-Progress -Activity "Processing Users" -Completed

# Export user information to CSV
$Report | Export-Csv -Path $Csvfile -NoTypeInformation -Encoding UTF8

Write-Host "Script completed. Results exported to $Csvfile." -ForegroundColor Cyan
```

3. **Save** the file as `Export-MFAstatus.ps1` in the `C:\scripts` folder.

---

## Export MFA Status Report to CSV 💾

### Before Running the Script:
1. Create a folder named `temp` on your **Desktop** (C:\temp).
2. Ensure you have the `Export-MFAstatus.ps1` script saved in the `C:\scripts` folder.

### Run the PowerShell Script:
1. **Open PowerShell as Administrator**.
2. Navigate to the folder where the script is located:

```powershell
cd C:\Users\Administrator\Desktop\scripts
```

3. Run the script:

```powershell
.\Export-MFAstatus.ps1
```

4. When prompted, **sign in** using your Microsoft admin credentials.  
   - Enter your password
   - Click **Sign in**
   
5. **Grant consent** for the necessary permissions:
   - **Enable Consent on behalf of your organization**
   - Click **Accept**

### Progress Bar:
The PowerShell script will show a progress bar and notify you when it's finished.

- **Example Output:**

```
Script completed. Results exported to C:\temp\MFAUsers_202309191236.csv.
```

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

You’ve successfully learned how to export all Microsoft 365 users' MFA status to a CSV file. By using the **Microsoft Graph PowerShell module**, the `Export-MFAstatus.ps1` script provides an efficient way to gather this information in a structured manner. This report helps you see which users have MFA enabled and which authentication methods they use.

**Next Steps**:  
- Review users with **MFA disabled** and encourage them to enable MFA for enhanced security.
