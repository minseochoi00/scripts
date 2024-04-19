# Import the Active Directory module to access AD-specific cmdlets
    Import-Module ActiveDirectory

# Obtain the current date and time to use as a reference
    $currentDate = Get-Date

# Output heading to clarify the script's purpose
    Write-Output "Checking for accounts locked within the last 48 hours..."

# Search for and retrieve details of all accounts that are currently locked out
    $lockedOutUsers = Search-ADAccount -LockedOut | Get-ADUser -Properties Name, SamAccountName, LockedOut, LastBadPasswordAttempt, lockoutTime, AccountLockoutTime | Where-Object {
        # Filter to include only those accounts locked out within the last 48 hours
        $_.lockoutTime -gt ($currentDate).AddHours(-48)
    }

# Check if the query returned any locked out accounts
    if ($lockedOutUsers) {
        # Output details of locked out accounts
        Write-Output "Locked out accounts within the last 48 hours:"
        foreach ($user in $lockedOutUsers) {
            # Format output for each user
            Write-Output "User: $($user.Name), Username: $($user.SamAccountName), Lockout Time: $(($user.lockoutTime).ToLocalTime()), Last Bad Password Attempt: $(($user.LastBadPasswordAttempt).ToLocalTime())"
        }
    } else {
        # Inform if no locked out accounts were found
        Write-Output "No accounts have been locked out within the last 48 hours."
    }
