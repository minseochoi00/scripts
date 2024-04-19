# Force an inventory update
  jamf recon
    # Description: Forces the managed device to update its inventory information on the Jamf Pro server. 
    # This is crucial after any significant change to the system, such as software installation or hardware upgrades, to ensure the server has accurate and up-to-date information.

# Run a specific policy using a custom event 
  jamf policy -event 'customEventName'
    # Description: Executes a policy associated with a custom event trigger defined in Jamf Pro. 
    # This can be used to deploy software, apply configurations, or run scripts based on specific actions or needs.


# Enforce management settings and restrictions 
  jamf manage
    # Description: Forces the reapplication of management settings and restrictions on the device. 
    # This is useful for ensuring that all managed devices comply with the latest configurations and security settings specified in Jamf Pro.

# Update managed preferences 
  jamf mcx
    # Description: Applies or updates managed preference settings for macOS clients, based on configurations defined in Jamf Pro. 
    # This is often used after updating policies that include settings for user environments and restrictions.

# Check network connectivity to Jamf Pro server 
  jamf checkNetwork
    # Description: Performs a check to ensure that the device can communicate with the Jamf Pro server. 
    # This is essential for troubleshooting issues related to network connectivity that might prevent the device from receiving policies or updates.
