<#
.SYNOPSIS
  Export ARM and Bicep Templates individually for given resource type in a given resource group.

.DESCRIPTION
  Export ARM and Bicep Templates individually for given resource type in a given resource group.
  Requires bicep module - Install-Module -Name Bicep

.PARAMETER Types
Array of Azure resource types to export as ARM and Bicep templates 

.PARAMETER SubscriptionId
Azure Subscription ID

.PARAMETER ResourceGroupName
Azure resource group name to iterate through resource types.

.INPUTS
  None

.OUTPUTS
  None

.NOTES
  Version:        1.0
  Author:         Jack Roper
  Creation Date:  11/10/2021
  Purpose/Change: Initial script development

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

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

[CmdletBinding()]

param(
    [Parameter(Mandatory)]    
    $Types = @(
        "microsoft.security/automations"
    ),
    [Parameter(Mandatory)]
    [string]$SubscriptionId = "a4e71d6e-6317-4d20-9162-c0d6def6c526",
    [Parameter(Mandatory)]
    [string]$ResourceGroupName = "siemExportRG"
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

Function Export-Templates($Types, $ResourceGroupName, $SubscriptionId) {

    # Export templates for each resource
    Begin{
        Write-Verbose -Message "Exporting Templates..."
    }
    Process {
        Try {
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
        }
        Catch {
            Write-Host -BackgroundColor Red "Error: $($_.Exception)"
        Break
        }
    }
    End {
        If ($?) {
            Write-Host 'Exported Completed'
          }
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Connect-Azure $SubscriptionId
Export-Templates $Types $ResourceGroupName $SubscriptionId