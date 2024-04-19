- Get-ADUser -Filter 'Name -like "*smith*"' -Properties *
  # Retrieves information about Active Directory user accounts.

- New-ADUser -Name "JohnDoe" -GivenName "John" -Surname "Doe" -SamAccountName "johndoe" -UserPrincipalName "johndoe@domain.com"
  # Creates a new user in Active Directory.

- Set-ADUser -Identity "johndoe" -Title "Senior Manager" -Department "Sales"
  # Modifies the properties of an Active Directory user account.

- Get-ADGroupMember -Identity "ITSupport"
  # Retrieves members of a specific AD group.

- Add-ADGroupMember -Identity "ITSupport" -Members "johndoe"
  # Adds one or more users to an AD group.
