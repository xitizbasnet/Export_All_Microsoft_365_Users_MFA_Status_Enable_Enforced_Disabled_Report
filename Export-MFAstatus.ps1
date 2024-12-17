# Connect to Microsoft Graph API
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All", "UserAuthenticationMethod.ReadWrite.All" -NoWelcome

# Create variable for the date stamp
$LogDate = Get-Date -f yyyyMMddhhmm

# Define CSV file export location variable
$Csvfile = "C:\temp\MFAUsers_$LogDate.csv"

# Get all Microsoft Entra ID users using the Microsoft Graph Beta API
$users = Get-MgBetaUser -All

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

    # Check authentication methods for each user
    $MFAData = Get-MgBetaUserAuthenticationMethod -UserId $user.Id

    # Retrieve the default MFA method
    $DefaultMFAUri = "https://graph.microsoft.com/beta/users/$($user.Id)/authentication/signInPreferences"
    try {
        $DefaultMFAMethod = Invoke-MgGraphRequest -Uri $DefaultMFAUri -Method GET
        if ($DefaultMFAMethod.userPreferredMethodForSecondaryAuthentication) {
            $ReportLine.DefaultMFAMethod = $DefaultMFAMethod.userPreferredMethodForSecondaryAuthentication
        }
        else {
            $ReportLine.DefaultMFAMethod = "Not set"
        }
    }
    catch {
        Write-Warning "Failed to retrieve default MFA method for $($user.UserPrincipalName): $_"
        $ReportLine.DefaultMFAMethod = "Error"
    }

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