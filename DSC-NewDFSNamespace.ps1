configuration NewDFSNamespace {
    param(
        [string]$DomainName,
        [string]$DFSRootShare,
        [string]$DFSRootServer
    )
    
    Import-DscResource -ModuleName 'cDFSn','xSmbShare'

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
            Description = 'Default DFSNamespace $DFSRootShare share' 
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
            DFSRootShare = $DFSRootshare
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

NewDFSNameSpace  `
    -ConfigurationData $ConfigData `
    -OutputPath "$pwd\modules\NewDFSNamespace" `
    -DomainName $env:USERDOMAIN `
    -DFSRootshare 'apps' `
    -DFSRootServer $env:COMPUTERNAME

# Make sure that LCM is set to continue configuration after reboot            
Set-DSCLocalConfigurationManager -Path .\modules\NewDFSNamespace –Verbose   

Start-DscConfiguration -Path .\modules\NewDFSNamespace -Wait -Verbose -force
