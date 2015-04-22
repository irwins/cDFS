# cDFS

Installation

To install cDFS Module
 * Unzip the content under $env:ProgramFiles\WindowsPowerShell\Modules folder

To confirm installation:
 * Run Get-DSCResource to see that all of the resources on this page are among the DSC Resources listed

# Example
The PowerShell script in **Misc/DSC-CreateNewDFSNamespace.ps1** is an example how to create a new DFSNamespace
```PowerShell
configuration NewDFSNamespace {
    param(
        [string]$DomainName,
        [string]$DFSRootShare,
        [string]$DFSRootServer
    )
    
    Import-DscResource -ModuleName 'cDFS','xSmbShare'

    Node $AllNodes.Where{$_.Role -eq 'Primary DFS'}.Nodename {             
        
        # Once in place no need to monitor    
        LocalConfigurationManager {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly' 
            RebootNodeIfNeeded = $true            
        }    

        # Mandatory for DFSRoot
        File RootFolder {
            Type = 'Directory'
            DestinationPath = "C:\DFSRoots\$(($DFSRootShare).ToUpper())"
            Ensure = 'Present'
        }

        # Mandatory for DFSShare
        xSmbShare RootShare { 
            Ensure = 'Present'  
            Name   = $(($DFSRootShare).ToUpper())
            Path = "C:\DFSRoots\$DFSRootShare"   
            ReadAccess = 'Everyone' 
            Description = "Default DFSNamespace $DFSRootShare share"
            FolderEnumerationMode = 'AccessBased'
            DependsOn = '[File]RootFolder'
        } 

        # Mandatory for DFSNamspaces
        WindowsFeature DFSNamespace {             
            Ensure = 'Present'             
            Name = 'FS-DFS-Namespace'             
        }            

        # Optional GUI tools            
        WindowsFeature DFSTools {             
            Ensure = 'Present'             
            Name = 'RSAT-DFS-Mgmt-Con'             
        } 

        # Create DFSNamespace
        cDFSnRoot DFSNamespace {
            Ensure = 'Present'
            DFSRootServer = $DFSRootServer
            DFSRootShare = $DFSRootShare
            DomainName = $DomainName  
            DependsOn = '[xSmbShare]RootShare', '[WindowsFeature]DFSNamespace'
        }
    }
}

# Configuration Data for DFS              
$ConfigData = @{             
    AllNodes = @(
        @{
            NodeName                    = '*'
            PSDscAllowPlainTextPassword = $True
        }             
        @{             
            Nodename = 'localhost'             
            Role = 'Primary DFS'             
        }            
    )             
}   
# HashTable with parameters for a new DFSNamespace
$paramNewDFSNamespace =  @{
    ConfigurationData = $ConfigData
    OutputPath = "$pwd\modules\NewDFSNamespace"
    DomainName = $env:USERDOMAIN
    DFSRootShare = 'home'
    DFSRootServer = $env:COMPUTERNAME
}

NewDFSNameSpace @paramNewDFSNamespace

# Make sure that LCM is set to continue configuration after reboot            
Set-DSCLocalConfigurationManager -Path .\modules\NewDFSNamespace -Verbose   

Start-DscConfiguration -Path .\modules\NewDFSNamespace -Wait -Verbose -Force
```
