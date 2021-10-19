<#
.SYNOPSIS
 
Quick way to write-host the uptime of a targetted machine
 
.DESCRIPTION
 
Attempts to discern uptime through Get-WMIObject
 
.PARAMETER Computers
 
$AppServers is either a single server, but can also be an array
 
.INPUTS
 
None. You cannot pipe objects to Get-Uptime
 
.EXAMPLE
 
PS> Get-Uptime -Computers yourfavoriteserver.contoso.com
#>
 
# Example PC Array
 
#$AppServers = @(
#
#"testserver1.contoso.com"
#"testserver2.contoso.com"
#"testserver3.contoso.com"
#"testserver4.contoso.com"
#)
 
$AppServers = "testserver1.contoso.com"
 
function Get-Uptime {
 
    param(
            [Parameter(Mandatory)]
            [Array] $Computers
        )
   
    $UptimeServerList | ForEach {    
        $computerName = $_
        $CurrentDate = Get-Date
        $CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
       
        If (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
   
            $uptime = Get-WmiObject Win32_OperatingSystem -ComputerName $computerName
            $bootTime = $uptime.ConvertToDateTime($uptime.LastBootUpTime)
            $elapsedTime = (Get-Date) - $bootTime
   
            $props = @{
                ComputerName = $computerName
                BootTime = $bootTime
                ElapsedTime = '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $elapsedTime.Days, $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds
            }
   
            New-Object PsObject -Property $props
   
        } Else {
   
            $props = @{
                ComputerName = $computerName
                BootTime = 'ERROR - Did not reply to ping'
                ElapsedTime = 'N/A'
            }
   
            New-Object PsObject -Property $props
   
        }
   
    } | Sort-Object ComputerName | Select-Object ComputerName,BootTime,ElapsedTime | Format-Table
    }
 
 
Get-Uptime -Computers $AppServers
 
 
 

