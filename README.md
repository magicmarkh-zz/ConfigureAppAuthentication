# Configure CyberArk Application Authentication Using the Credential Provider
Use this script to update your application's authentication information in CyberArk.

## Currently Supported
- configure hash authentication
- Credential Provider Only

## Not supported
- path authentication
- IP/Address Hostname authentication
- OS User authentication

## Variable List
| Variable | Description | Example | Default | Required |
| --- | --- | --- | --- | --- |
| PVWAURL | Address of your PVWA URL | https://pvwa1.yourbusiness.com | N/A | True |
| logonCredentail | PSCredential of API user | $cred = Get-Credentail | N/A | True |
| dllPath | Path of folder containing DLL's to be hashed | "c:\intepub\wwwroot\yourapp\bin" | N/A | True |
| cyberArkAppID | name of the configured CyberArk application | TestApp | N/A | True |
| aimInstallationPath | path of CyberArk Password Provider install folder | "e:\your\install\path" | "C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider" | False |
| logfile | location of logfile for script | "c:\your\log\path\file.log" | "c:\tmp\logs\AddDependency\UpdateAppAuthMethods.log" | False |
| deleteOldAppAuthInfo | should CyberArk delete older authentication information of the same type | $true | False | False |

## Usage

Call the script providing minimum information necessary, accepting defaults for non-required variables.
> $PVWAURL = "https://pvwa1.yourcompany.com"  
> $logonCredential = Get-Credential  
> $dllPath = "c:\intepub\yourapp\bin"  
> $cyberArkAppID = "yourAppID"  
> .\updateAppAuth.ps1 -PVWAURL $PVWAURL -logonCredentail $logonCredential -dllPath $dllPath -CyberArkAppID $cyberArkAppID

Call the script with optional items configured
> $PVWAURL = "https://pvwa1.yourcompany.com"  
> $logonCredential = Get-Credential  
> $dllPath = "c:\intepub\yourapp\bin"  
> $cyberArkAppID = "yourAppID"  
> $logfile = "e:\tmp\logs\updateAppAuth.log"  
> .\updateAppAuth.ps1 -PVWAURL $PVWAURL -logonCredentail $logonCredential -dllPath $dllPath -CyberArkAppID $cyberArkAppID -logfile $logfile -deleteOldAppAuthInfo $true


