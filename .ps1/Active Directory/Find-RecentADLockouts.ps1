# Import Active Directory module
    Import-Module ActiveDirectory

# Get the current date and time
    $currentDate = Get-Date

# Find all user accounts locked out within the last 24 hours
    $lockedOutUsers = Search-ADAccount -LockedOut | Get-ADUser -Properties Name, LockedOut, LastBadPasswordAttempt, lockoutTime, AccountLockoutTime | Where-Object {
        $_.lockoutTime -gt ($currentDate).AddHours(-24)
    }

# Check if any users were found
    if ($lockedOutUsers) {
            # Output details of locked out accounts
            Write-Output "Locked out accounts within the last 24 hours:"
                foreach ($user in $lockedOutUsers) {
                    Write-Output "User: $($user.Name), Lockout Time: $(($user.lockoutTime).ToLocalTime()), Last Bad Password Attempt: $(($user.LastBadPasswordAttempt).ToLocalTime())"
                }
    } else {
        Write-Output "No accounts have been locked out within the last 24 hours."
    }
