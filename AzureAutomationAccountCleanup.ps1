<#
.SYNOPSIS
  Script to query the jobs, schedules and webhooks linked to an Azure Runbook inside an automation account. 
.DESCRIPTION
  The script can be used to identify redundnant Runbooks without and jobs, schedules or webhooks. Outputs a CSV listing each so they can be cross referenced with the runbooks list.
.PARAMETER SubscriptionId
  Azure Subscription ID
.PARAMETER ResourceGroupName
  Azure Resource group name where the automation account resides
.PARAMETER AutomationAccountName
  Azure Automation Account Name
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         Jack Roper
  Creation Date:  12/10/2021
  Purpose/Change: Initial script development
.EXAMPLE
  Connect-Azure $SubscriptionId
  Get-Runbooks $SubscriptionId $ResourceGroupName $AutomationAccountName
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

Function Get-Runbooks($SubscriptionId, $ResourceGroupName, $AutomationAccountName) {
  Begin {
    Write-Verbose -Message "Querying Runbooks..."
  }
  Process {
    Try {
      $Runbooks = Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
      Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | Select-Object -Property Name, LastModifiedTime, RunbookType, State | Export-Csv -Path ".\Runbooks.csv" -NoTypeInformation -Append
      foreach ($Runbook in $Runbooks) {
        Get-AzAutomationJob -RunbookName $Runbook.Name -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | Select-Object -Property RunbookName, Status, StartTime, EndTime | Export-Csv -Path ".\Jobs.csv" -NoTypeInformation -Append
        Get-AzAutomationScheduledRunbook -RunbookName $Runbook.Name -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | Select-Object -Property ScheduleName, RunbookName | Export-Csv -Path ".\Schedules.csv" -NoTypeInformation -Append
        Get-AzAutomationWebhook -RunbookName $Runbook.Name -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | Select-Object -Property Name, RunbookName, LastInvokedTime, IsEnabled | Export-Csv -Path ".\Webhooks.csv" -NoTypeInformation -Append
      }
    }
    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
    Break
    }
  }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Connect-Azure $SubscriptionId
Get-Runbooks $SubscriptionId $ResourceGroupName $AutomationAccountName