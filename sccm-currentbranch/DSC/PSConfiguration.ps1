﻿configuration PSConfiguration
{
   param
   (
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [String]$DCName,
        [Parameter(Mandatory)]
        [String]$DPMPName,
        [Parameter(Mandatory)]
        [String]$ClientName,
        [Parameter(Mandatory)]
        [String]$DNSIPAddress,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName TemplateHelpDSC
    Import-DscResource -ModuleName xSmbShare
    Import-DscResource -ModuleName ComputerManagementDsc
    
    $LogFolder = "TempLog"
    $CM = "CMCB"
    $LogPath = "c:\$LogFolder"
    $DName = $DomainName.Split(".")[0]
    $DCComputerAccount = "$DName\$DCName$"
    $DPMPComputerAccount = "$DName\$DPMPName$"
    
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node LOCALHOST
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
        
        AddBuiltinPermission AddSQLPermission
        {
            Ensure = "Present"
        }

        SetDNS DnsServerAddress
        {
            DNSIPAddress = $DNSIPAddress
            Ensure = "Present"
            DependsOn = "[AddBuiltinPermission]AddSQLPermission"
        }

        WaitForDomainReady WaitForDomain
        {
            Ensure = "Present"
            DCName = $DCName
            DependsOn = "[SetDNS]DnsServerAddress"
        }

        WindowsFeature BITS
        {             
            Ensure = "Present"             
            Name = "BITS"             
        }

        WindowsFeature BITS-IIS-Ext
        {             
            Ensure = "Present"             
            Name = "BITS-IIS-Ext"             
        }

        WindowsFeature Web-Basic-Auth
        {             
            Ensure = "Present"             
            Name = "Web-Basic-Auth"             
        }

        WindowsFeature Web-IP-Security
        {             
            Ensure = "Present"             
            Name = "Web-IP-Security"             
        }

        WindowsFeature Web-Scripting-Tools
        {             
            Ensure = "Present"             
            Name = "Web-Scripting-Tools"
        }

        WindowsFeature Web-Mgmt-Tools
        {             
            Ensure = "Present"             
            Name = "Web-Mgmt-Tools"             
        }

        WindowsFeature Web-Mgmt-Service
        {             
            Ensure = "Present"             
            Name = "Web-Mgmt-Service"             
        }
    
        WindowsFeature Web-WMI
        {             
            Ensure = "Present"             
            Name = "Web-WMI"             
        }

        WindowsFeature Web-Lgcy-Scripting
        {             
            Ensure = "Present"             
            Name = "Web-Lgcy-Scripting"             
        }
        
        WindowsFeature Web-Lgcy-Mgmt-Console
        {             
            Ensure = "Present"             
            Name = "Web-Lgcy-Mgmt-Console"             
        }

        WindowsFeature Web-Mgmt-Console
        {             
            Ensure = "Present"             
            Name = "Web-Mgmt-Console"             
        }

        WindowsFeature Web-Asp-Net
        {             
            Ensure = "Present"             
            Name = "Web-Asp-Net"             
        }

        WindowsFeature Web-ASP
        {             
            Ensure = "Present"             
            Name = "Web-ASP"             
        }

        WindowsFeature Web-Windows-Auth
        {             
            Ensure = "Present"             
            Name = "Web-Windows-Auth"             
        }

        WindowsFeature Web-Url-Auth
        {             
            Ensure = "Present"             
            Name = "Web-Url-Auth"             
        }

        WindowsFeature Rdc
        {             
            Ensure = "Present"             
            Name = "Rdc"             
        }

        Computer JoinDomain
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds # Credential to join to domain
            DependsOn = "[WaitForDomainReady]WaitForDomain"
        }
        
        File ShareFolder
        {            
            DestinationPath = $LogPath     
            Type = 'Directory'            
            Ensure = 'Present'
            DependsOn = "[Computer]JoinDomain"
        }

        xSmbShare DomainSMBShare
        {
            Ensure = "Present"
            Name   = $LogFolder
            Path =  $LogPath
            ReadAccess = @($DCComputerAccount)
            Description = "This is a temp log Share"
            DependsOn = "[File]ShareFolder"
        }
        
        Firewall TCPInbound
        { 
            Name = 'TCPInbound' 
            DisplayName = 'TCP Inbound' 
            Group = 'For SCCM PS' 
            Ensure = 'Present' 
            Enabled = 'True' 
            Profile = ('Domain', 'Private', 'Public') 
            Direction = 'InBound' 
            LocalPort = ('80','135','443','445','1433','1723','1024-65535') 
            Protocol = 'TCP' 
            Description = 'TCP Inbound'
            DependsOn = "[Computer]JoinDomain"
        }

        Firewall TCPOutbound
        { 
            Name = 'TCPOutbound' 
            DisplayName = 'TCP Outbound' 
            Group = 'For SCCM PS' 
            Ensure = 'Present' 
            Enabled = 'True' 
            Profile = ('Domain', 'Private', 'Public') 
            Direction = 'Outbound' 
            LocalPort = ('80','135','389','443','445','636','1433','1723','3268','3269','1024-65535') 
            Protocol = 'TCP' 
            Description = 'TCP Inbound'
            DependsOn = "[Computer]JoinDomain"
        }

        Firewall UDPOutbound
        { 
            Name = 'UDPOutbound' 
            DisplayName = 'UDP Outbound' 
            Group = 'For SCCM PS' 
            Ensure = 'Present' 
            Enabled = 'True' 
            Profile = ('Domain', 'Private', 'Public') 
            Direction = 'Outbound' 
            LocalPort = ('9','135','636') 
            Protocol = 'UDP' 
            Description = 'HTTP(S) Inbound'
            DependsOn = "[Computer]JoinDomain"
        }

        Firewall UDPInbound
        { 
            Name = 'UDPInbound' 
            DisplayName = 'UDP Inbound' 
            Group = 'For SCCM PS' 
            Ensure = 'Present' 
            Enabled = 'True' 
            Profile = ('Domain', 'Private', 'Public') 
            Direction = 'Outbound' 
            LocalPort = ('135') 
            Protocol = 'UDP' 
            Description = 'UDP Inbound'
            DependsOn = "[Computer]JoinDomain"
        }

        InstallADK ADKInstall
        {
            ADKPath = "C:\adksetup.exe"
            ADKWinPEPath = "c:\adksetupwinpe.exe"
            Ensure = "Present"
            DependsOn = "[Computer]JoinDomain"
        }

        WaitForConfigurationFile DelegateControl
        {
            Role = "DC"
            MachineName = $DCName
            LogFolder = $LogFolder
            ReadNode = "DelegateControl"
            Ensure = "Present"
            DependsOn = "[InstallADK]ADKInstall"
        }

        ChangeSQLServicesAccount ChangeToLocalSystem
        {
            SQLInstanceName = "MSSQLSERVER"
            Ensure = "Present"
            DependsOn = "[WaitForConfigurationFile]DelegateControl"
        }

        DownloadSCCM DownLoadSCCM
        {
            CM = $CM
            ExtPath = $LogPath
            Ensure = "Present"
            DependsOn = "[ChangeSQLServicesAccount]ChangeToLocalSystem"
        }

        xSmbShare CMSourceSMBShare
        {
            Ensure = "Present"
            Name   = $CM
            Path =  "c:\$CM"
            ReadAccess = @($DCComputerAccount)
            Description = "This is CM source Share"
            DependsOn = "[DownloadSCCM]DownLoadSCCM"
        }

        RegisterTaskScheduler InstallAndUpdateSCCM
        {
            TaskName = "ScriptWorkFlow"
            ScriptName = "ScriptWorkFlow.ps1"
            ScriptPath = $PSScriptRoot
            ScriptArgument = "$DomainName $CM $DName\$($Admincreds.UserName) $DPMPName $ClientName"
            Ensure = "Present"
            DependsOn = "[xSmbShare]CMSourceSMBShare"
        }
    }
}