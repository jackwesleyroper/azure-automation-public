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
    $SubscriptionId = "xxxx",
    $ResourceGroupName = "xxxx-rg",
    $AutomationAccountName = "xxxx-aa"
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------


[CmdletBinding()]

param(
    [Parameter(Mandatory)]    
    [string]$SubscriptionId = "xxxx",
    [Parameter(Mandatory)]
    [string]$ResourceGroupName = "xxxx",
    [Parameter(Mandatory)]
    [string]$AutomationAccountName = "xxxx"
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

Function Export-Runbooks($ResourceGroupName, $AutomationAccountName, $SubscriptionId) {

    Begin{
        Write-Verbose -Message "Set folder path..."
    }
    Process{
        if (Test-Path -PathType Container -Path ($SubscriptionName + "\" + $ResourceGroupName + "\" + $AutomationAccountName + "\runbooks\ExportedRunbooks")) {
            write-host("Output folder already exists")
            $OutputFolder = ($SubscriptionName + "\" + $ResourceGroupName + "\" + $AutomationAccountName + "\runbooks\ExportedRunbooks")
        }else {
            write-host("Creating output folder")
            $OutputFolder = New-Item -ItemType Directory -Force -Path ($SubscriptionName + "\" + $ResourceGroupName + "\" + $AutomationAccountName + "\runbooks\ExportedRunbooks")
        }

        Try{
            Write-Verbose -Message "Exporting Runbooks..."
            $AllRunbooks = Get-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName
            $AllRunbooks | Export-AzAutomationRunbook -OutputFolder $OutputFolder

            Write-Verbose -Message "Exporting Variables..."
            $Variables = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName
            $VariablesFilePath = $OutputFolder + "\RunbookVariables.csv"
            $Variables | Export-Csv -Path $VariablesFilePath -NoTypeInformation
        }
        Catch {
            Write-Host -BackgroundColor Red "Error: $($_.Exception)"
        Break
        }
    }
    End {
        If ($?) {
          Write-Host 'Export Complete.'
        }
    }

}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Connect-Azure $SubscriptionId
Export-Runbooks $ResourceGroupName $AutomationAccountName $SubscriptionId