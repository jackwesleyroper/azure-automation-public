<#
.SYNOPSIS
  Renews the application registration secret and stores the value in key vault.
.DESCRIPTION
  This script is used to generate a new secret for an application registration in Azure AD. The expiry date can be set as a number of years from the current time and date. The secret generated is stored in 
  a specified keyvault, the AppID, ObjectID and KeyID of the application registration are stored in the ContentType field of the secret. 
.PARAMETER KeyVaultName
  Name of the Key Vault to store the secret value of the secret genrated for the application registration.
.PARAMETER DisplayName
  Name of the Application registration in Azure AD to update.
.PARAMETER SubscriptionID
  ID of the Azure Subscription to run the script.
.PARAMETER ExpiresYears
  Expiry date of the newly generated secret in the number of years from todays date.
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         Jack Roper
  Creation Date:  11/01/2022
  Purpose/Change: Initial script development
.EXAMPLE
  ./New-AzADAppCredential.ps1 -KeyVaultName testingpskv -DisplayName testpsapp -SubscriptionID xxxx -ExpiresYears 1
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

[CmdletBinding()]

param (
  [Parameter(Mandatory = $true)]
  [string]$KeyVaultName,
  [Parameter(Mandatory = $true)]
  [string]$DisplayName,
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionID,
  [Parameter(Mandatory = $true)]
  [string]$ExpiresYears
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Connect-Azure($SubscriptionId) {

  Begin {
    Write-Verbose -Message "Connecting to Azure..."
    Connect-AzAccount
    Set-AzContext -SubscriptionId $SubscriptionId
  }
  Process {
    Try {
        Select-AzSubscription -SubscriptionId $SubscriptionId
        $SubscriptionName = (Get-AzSubscription -SubscriptionId $SubscriptionId).Name
    }
    Catch {
        Write-Host -BackgroundColor Red "Error: $($_.Exception)"
    Break
    }
  }
  End {
    If ($?) {
      Write-Host 'Connected to Azure Successfully.'
      Write-Host 'Selected Subscription' $SubscriptionName'.'
    }
  }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Connect-Azure $SubscriptionId

# Set the expiration date from today to x years
$Expires = (Get-Date).AddYears($ExpiresYears).ToUniversalTime()

# Regenerate the App Registration Secret
$App = Get-AzADApplication -DisplayName $DisplayName | New-AzADAppCredential -EndDate $Expires

# Convert the password to a secure string
$SecureStringPassword = ConvertTo-SecureString -String $App.SecretText -AsPlainText -Force

# Set the application registration name to the same as the app display name
$AppRegName = Get-AzADApplication -DisplayName $DisplayName

# Get app credential to pull out KeyId
$SecretValue = Get-AzADAppCredential -DisplayName $DisplayName

# Check Key Vault for existing secret
$ExistingSecret = Get-AzKeyVaultSecret –VaultName $KeyVaultName –Name $AppRegName.DisplayName

if ($null -eq $ExistingSecret) {
  Set-AzKeyVaultSecret –VaultName $KeyVaultName –Name $AppRegName.DisplayName -SecretValue $SecureStringPassword -Expires $Expires
  Write-Host "Secret does not exist. Creating new secret in the Key Vault"
  $NewSecret = Get-AzKeyVaultSecret –VaultName $KeyVaultName –Name $AppRegName.DisplayName
  Update-AzKeyVaultSecret –VaultName $KeyVaultName –Name $AppRegName.DisplayName -ContentType ("App ID:" + $AppRegName.AppId + " Object ID:" + $AppRegName.Id + " Key ID:" + $SecretValue.KeyId[0] + " SecretID:" + $NewSecret.Version)
}
else {
# Update the Secret Value in the Key Vault
  Set-AzKeyVaultSecret –VaultName $KeyVaultName –Name $AppRegName.DisplayName -SecretValue $SecureStringPassword -Expires $Expires
  Write-Host "Updating the existing secret with the new value"
  $NewSecret = Get-AzKeyVaultSecret –VaultName $KeyVaultName –Name $AppRegName.DisplayName
  Update-AzKeyVaultSecret –VaultName $KeyVaultName –Name $AppRegName.DisplayName -ContentType ("App ID:" + $AppRegName.AppId + " Object ID:" + $AppRegName.Id + " Key ID:" + $SecretValue.KeyId[0] + " SecretID:" + $NewSecret.Version)
}
