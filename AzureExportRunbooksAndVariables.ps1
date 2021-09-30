<#
.SYNOPSIS
Export all runbooks and variables from an automation account

.DESCRIPTION
Note: Exports all runbooks as .ps1 even if they are really Python 2 runbooks. 
Places the files in a folder structure in the format [SubscriptionName\ResourceGroupName\AutomationAccountName\runbooks\ExportedRunbooks]
Variables are exported to a CSV file and placed in the same directory as the Runbooks.

.PARAMETER AutomationAccountName
Name of the automation account to Export the runbooks and variables from.

.PARAMETER subscriptionId
Azure Subscription ID

.PARAMETER resourceGroupName
Azure resource group name to iterate through resource types.

.EXAMPLE
    $SubscriptionId = "xxxx",
    $ResourceGroupName = "xxxx-rg",
    $AutomationAccountName = "xxxx-aa"
#>

[CmdletBinding()]

param(
    $SubscriptionId = "xxxx",
    $ResourceGroupName = "xxxx",
    $AutomationAccountName = "xxxx"
)

# Login and set context
#Connect-AzAccount
#Set-AzContext -SubscriptionId $SubscriptionId

# Select subscription
Select-AzSubscription -SubscriptionId $SubscriptionId
$subscriptionName = (Get-AzSubscription -SubscriptionId $SubscriptionId).Name

# Set folder path
if (Test-Path -PathType Container -Path ($SubscriptionName + "\" + $ResourceGroupName + "\" + $AutomationAccountName + "\runbooks\ExportedRunbooks")) {
    write-host("Output folder already exists")
    $OutputFolder = ($SubscriptionName + "\" + $ResourceGroupName + "\" + $AutomationAccountName + "\runbooks\ExportedRunbooks")
}else {
    write-host("Creating output folder")
    $OutputFolder = New-Item -ItemType Directory -Force -Path ($SubscriptionName + "\" + $ResourceGroupName + "\" + $AutomationAccountName + "\runbooks\ExportedRunbooks")
}

# Exporting Runbooks
$AllRunbooks = Get-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName
$AllRunbooks | Export-AzAutomationRunbook -OutputFolder $OutputFolder

# Exporting Variables
$Variables = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName
$VariablesFilePath = $OutputFolder + "\RunbookVariables.csv"
$Variables | Export-Csv -Path $VariablesFilePath -NoTypeInformation
