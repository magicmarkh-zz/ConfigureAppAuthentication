#Requires -RunAsAdministrator
[CmdletBinding(DefaultParametersetName="Create")]
param
(
	[Parameter(Mandatory=$true,HelpMessage="Please enter your PVWA address (For example: https://pvwa.mydomain.com)")]
	[Alias("url")]
	[String]$PVWAURL,
    
    [Parameter(Mandatory=$true,HelpMessage="PSCredential file for logging into the CyberArk Vault via API")]
	[Alias("logonCredential")]
    [System.Management.Automation.PSCredential]$logonCred,

    [Parameter(Mandatory=$true,HelpMessage="Folder containing DLLs to be hashed")]
    [String]$dllPath,

    [Parameter(Mandatory=$true,HelpMessage="CyberArk App Id")]
	[String]$cyberArkAppID = "aimexample",
    
    [Parameter(Mandatory=$false,HelpMessage="Install location of CyberArk AIM. Default: C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider")]
    [String]$aimInstallPath = "C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider",

    [Parameter(Mandatory=$false,HelpMessage="Location of log file, default is c:\tmp\logs\AddDependency\UpdateAppAuthMethods.log")]
    [String]$logfile = "c:\tmp\logs\AddDependency\UpdateAppAuthMethods.log",
  
    [Parameter(Mandatory=$false,HelpMessage="Should old applicaiton authorization info be deleted?")]
    [String]$deleteOldAppAuthInfo = $false
)


#region Functions
Function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
        [String]
        $Level = "INFO",

        [Parameter(Mandatory = $True)]
        [string]
        $Message,

        [Parameter(Mandatory = $False)]
        [string]
        $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    If ($logfile) {
        Add-Content $logfile -Value $Line
    }
    Else {
        Write-Output $Line
    }
}

function Exit-WithLogEntry ($level, $closeSession, $msg) {
    Write-Log -Level $level -logfile $logfile -Message $msg
    Write-Log -Level INFO -logfile $logfile -Message "Exiting early due to error."
    Write-Host "Error. Please check logs at $logfile for more details." 
    if ($closeSession) { Close-PASSession }
    exit
}

#endregion Functions

#region pre-reqs

#create the logfile if it doesn't exist
if (!(Test-Path $logfile)) {
    New-Item -Path $logfile -ItemType File -Force | Out-Null
}

#log entry to start script
Write-Log -Level INFO -logfile $logfile -Message "CyberArk Application Security."



#check to see if psPAS is installed
if (Get-Module -ListAvailable -Name psPAS) {
    Write-Log -Level INFO -logfile $logfile -Message "psPAS Module exists, continuing installation."
}
else {
    try {
        Install-Module -Name psPAS -Force -Scope CurrentUser
    }
    catch {
        Exit-WithLogEntry -level ERROR -closeSession $false -msg "Could not install psPAS module: $($_.Exception.Message)"
    }
}

#endregion pre-reqs

#get new application information
try {
    $newAppHashes = & "$($aimInstallPath)\Utils\NETAIMGetAppInfo.exe" GetHash /AppExecutablesPattern="$dllPath\*.dll"
}
catch {
    Exit-WithLogEntry -level ERROR -closeSession $false -msg "Could not retrieve application hash information: $($_.Exception.Message)"
}

#establish session to the vault
try {
    New-PASSession -Credential $logonCred -BaseURI $PVWAURL
    Write-Log -Level INFO -logfile $logfile -Message "Session to vault established with user $($logonCred.username)."
}
catch {
    Exit-WithLogEntry -level ERROR -closeSession $false -msg "Could not establish session to vault with user $($logonCred.username): $($_.Exception.Message)"
}

#get current app authorization info
if ($true -eq $deleteOldAppAuthInfo) {
    try {
        $authMethods = Get-PASApplicationAuthenticationMethod -AppID $cyberArkAppID
        if (!$authMethods) {
            Write-Log -Message "No authentication methods currently exist for $($cyberArkAppID). Nothing to remove."-Level INFO -logfile $logfile
        }
        else {
            foreach ($authMethod in $authMethods) {
                Remove-PASApplicationAuthenticationMethod -AppID $cyberArkAppID -AuthID $authMethod.authid

            }
        }
    }
    catch {
        Exit-WithLogEntry -level ERROR -closeSession $true -msg "Error retrieving authentication methods for CyberArk application $($cyberArkAppID): $($_.Exception.Message)"
    }
    finally{
        Write-Log -Level INFO -logfile $logfile -Message "Authentication methods removed for CyberArk App $($cyberArkAppID)."
    }
}

#update app auth
try {
    for ($i=0; $i -lt $newAppHashes.Count - 1; $i++)
    {
        Add-PASApplicationAuthenticationMethod -AppID $cyberArkAppID -hash $newAppHashes[$i]
    }
}
catch {
    Exit-WithLogEntry -level -closeSession $true -msg "Error updating application authentication information for CyberArk application $($cyberArkAppID): $($_.Exception.Message)"
}
finally{
    Write-Log -Level INFO -logfile $logfile -Message "$($i) authentication hashes added for CyberArk application $($cyberArkAppID)."
}

Close-PASSession
Write-Log -Level INFO -logfile $logfile -Message "Authentication information successfully updated for CyberArk application $($cyberArkAppID)."
#logout