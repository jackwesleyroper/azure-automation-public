<#
.SYNOPSIS
Export ARM and Bicep Templates individually for given resource type in a given resource group.

.DESCRIPTION
Export ARM and Bicep Templates individually for given resource type in a given resource group. 
Takes one copy with the -IncludeParameterDefaultValue and one with the -SkipAllParameterization flag. These are then converted to Bicep files.
Requires bicep module - Install-Module -Name Bicep
Places the files in a folder structure in the format [SubscriptionName\ResourceGroupName\ResourceType\[WithParams][NoParams]\ResourceName]

.PARAMETER Types
Array of Azure resource types to export as ARM and Bicep templates 

.PARAMETER SubscriptionId
Azure Subscription ID

.PARAMETER ResourceGroupName
Azure resource group name to iterate through resource types.

.EXAMPLE
To export all Azure alerts, monitors and related resources:

$Types = @(
        "microsoft.alertsmanagement/smartdetectoralertrules",
        "Microsoft.Automation/automationAccounts/runbooks",
        "microsoft.insights/activitylogalerts",
        "microsoft.insights/scheduledqueryrules",
        "microsoft.security/automations",
        "microsoft.insights/webtests",
        "microsoft.insights/components",
        "microsoft.insights/actiongroups",
        "microsoft.insights/metricalerts"
    ),

    $SubscriptionId = "xxxx",
    $ResourceGroupName = "xxxx-rg"
#>

[CmdletBinding()]

param(
    $Types = @(
        "microsoft.alertsmanagement/smartdetectoralertrules",
        "Microsoft.Automation/automationAccounts/runbooks",
        "microsoft.insights/activitylogalerts",
        "microsoft.insights/scheduledqueryrules",
        "microsoft.security/automations",
        "microsoft.insights/webtests",
        "microsoft.insights/components",
        "microsoft.insights/actiongroups",
        "microsoft.insights/metricalerts"
    ),

    $SubscriptionId = "xxxx",
    $ResourceGroupName = "xxxx"
)

# Login and set context
#Connect-AzAccount
#Set-AzContext -SubscriptionId $SubscriptionId

# Select subscription
Select-AzSubscription -SubscriptionId $SubscriptionId
$SubscriptionName = (Get-AzSubscription -SubscriptionId $SubscriptionId).Name

# Export templates for each resource
foreach ($Type in $Types) {
    $ResourceTypes = (Get-AzResource -ResourceGroupName $ResourceGroupName | Where-Object {$_.ResourceType -eq $Type} | Select-Object * )
    $ResourceTypeFolderName = $Type -replace ".*/"
  
    foreach ($Resource in $ResourceTypes) {
        $FileName = $SubscriptionName + "\" + $ResourceGroupName + "\" + $ResourceTypeFolderName + "\WithParams\" + $Resource.Name
        $FileNameNoParams = $SubscriptionName + "\" + $ResourceGroupName + "\" + $ResourceTypeFolderName + "\NoParams\" + $Resource.Name
        Export-AzResourceGroup -ResourceGroupName $ResourceGroupName -Resource $Resource.ResourceId -Path $FileName -IncludeParameterDefaultValue
        Export-AzResourceGroup -ResourceGroupName $ResourceGroupName -Resource $Resource.ResourceId -Path $FileNameNoParams -SkipAllParameterization
        $BicepFileName = ($FileName + ".json")
        $BicepFileNameNoParams = ($FileNameNoParams + ".json")
        ConvertTo-Bicep -Path $BicepFileName
        ConvertTo-Bicep -Path $BicepFileNameNoParams
    }
}
