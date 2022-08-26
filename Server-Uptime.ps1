<#
.SYNOPSIS
 
Create an uptime report based on your selected OUs. 
 
.DESCRIPTION

Attempts to discern uptime through Get-WMIObject after a ping and connection check, and create a report with PSWriteHTML
 
#>
# Report Name

$ReportName = "Uptime"

# What OUs are we targetting?
$Full_OU_Paths = @(
"contoso.com/Servers",
"contoso.com/Domain Controllers")

# Should we keep the HTML report that is generated? If you don't keep it, you should at least email it, as it will be deleted!
$KeepFile = "Yes"

# Where should we save it? If left blank, Default is "$PSScriptRoot"
$FilePath = "$PSScriptRoot"

# Should we email the report?
$EmailorNot = "Yes"

# Email Report Settings
# Who to send the report to, commas separated. Example: "Test Email <test@contoso.com>", "Test Email 2 <test2@contoso.com>"
$To = "billgates@microsoft.com"

# Email Body, Plain Text until HTML provided.
$Body = "Please find the Uptime Report Attached"

# Email Subject. Report Name and Date are default
$Subject = "$ReportName Report - $Today"  

# Your SMTP Relay
$SmtpServer = "exchange.contoso.com"

# Sender of report email
$From = "Custom Alerts <uh-oh@contoso.com>"


    



#################### SCRIPT START ####################

$OU_Paths = foreach ($Full_OU_Path in $Full_OU_Paths)
{Get-ADOrganizationalUnit -Filter * -Properties CanonicalName,Name,DistinguishedName | Where-Object -FilterScript {$_.CanonicalName -like "*$Full_OU_Path"} | Select-Object -ExpandProperty DistinguishedName}

$ServerList = @()
$Today = Get-Date

foreach ($OU_Path in $OU_Paths){
    $ServerList += ((Get-ADComputer -Filter "OperatingSystem -Like '*Windows Server*' -and Enabled -eq 'True' -and objectClass -eq 'computer'" `
     -SearchBase $OU_Path -SearchScope Subtree `
     -Properties DNSHostName,Name,Enabled,ObjectClass)| Select-Object -ExpandProperty DNSHostName)
    }

$Results = ($ServerList | ForEach {    
        $computerName = $_
        $CurrentDate = Get-Date
        $CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
        If ((Test-Connection -ComputerName $computerName -Count 1 -Quiet)) {


        $uptime = Get-WmiObject Win32_OperatingSystem -ComputerName $computerName -ErrorAction SilentlyContinue

        If ($NULL -ne $uptime) {
           
            $uptime = Get-WmiObject Win32_OperatingSystem -ComputerName $computerName -ErrorAction SilentlyContinue
            $bootTime = ($uptime.ConvertToDateTime($uptime.LastBootUpTime))
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
                BootTime = 'ERROR - Device Unreachable (WMI)'
                ElapsedTime = 'N/A'
            }
            Write-Output "NULL Uptime found for $computername"
            New-Object PsObject -Property $props
   } }

   Else {
   
            $props = @{
                ComputerName = $computerName
                BootTime = 'ERROR - Device Unpingable'
                ElapsedTime = 'N/A'
            }
            Write-Output "No ping possible for $computername"
            New-Object PsObject -Property $props
   }
        
   
    } | Sort-Object ComputerName | Select-Object ComputerName,BootTime,ElapsedTime | Where {$null -ne $_.Computername} )
    
$Results | Out-HTMLView -DisablePaging -filePath "$FilePath\$ReportName.html" -DefaultSortColumn ElapsedTime -DefaultSortOrder Descending -TextWhenNoData "NO DATA AVAILABLE"

if ($EmailorNot -eq "Yes"){
$EmailSettings = @{ 
    To         = $To
    Body       = $Body
    Subject    = $Subject  
    SmtpServer = $SmtpServer
    From       = $From
    Attachments = "$FilePath\$ReportName.html"
    } 

    Send-MailMessage @EmailSettings }

if ($KeepFile -eq "Yes"){
# if you run this in a window session, the HTML creation opens your browser
Taskkill /IM iexplore.exe -force
Taskkill /IM msedge.exe -force
Remove-Item -Path $FilePath\$ReportName.html -Force}