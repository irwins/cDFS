function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DomainName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootServer,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootShare
	)

    Write-Verbose -Message "verify if DFSNamespace $DFSRootShare exists"
    $DFSNamespace = Get-WmiObject -Class Win32_DFSNode | Where-Object Name -match $DFSRootShare
    if($DFSNamespace) {
        Write-Verbose -Message "DFSNamespace $DFSRootShare in domain $DomainName is present."
        $Ensure = 'Present' 
    }
    else {
        Write-Verbose -Message "DFSNamespace $DFSRootShare in domain $DomainName is absent."
        $Ensure = 'Absent' 
    }

	$returnValue = @{
		DomainName = $DomainName
		DFSRootServer = $DFSRootServer
		DFSRootShare = $DFSRootShare
		Ensure = $Ensure
	}

	$returnValue
}


function Set-TargetResource {
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DomainName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootServer,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootShare,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure
	)
    try {
        $parameters = $PSBoundParameters.Remove('Debug');
        ValidateProperties @PSBoundParameters -Apply
    }
    catch {
        Write-Error -Message "Error setting DFSNamespace \\$DomainName\$DFSRootShare. $_"
        throw $_
    }
}


function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DomainName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootServer,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootShare,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure
	)

    try {
        $parameters = $PSBoundParameters.Remove('Debug');
        ValidateProperties @PSBoundParameters    
    }
    catch {
        Write-Error -Message "Error testing DFSNamespace \\$DomainName\$DFSRootShare. $_"
        throw $_
    }
}

function ValidateProperties {
    param(
		[parameter(Mandatory = $true)]
		[System.String]
		$DomainName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootServer,

		[parameter(Mandatory = $true)]
		[System.String]
		$DFSRootShare,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure,

        [Switch]$Apply
    )

    # Check if DFSNamespace exists

    Write-Verbose -Message "verify if DFSNamespace $DFSRootShare exists"
    
    $DFSNameSpace = Get-WmiObject -Class Win32_DFSNode | Where-Object Name -eq "\\$DomainName\$DFSRootShare"

    if ($DFSNameSpace) {
        Write-Verbose -Message "DFSNamespace $DFSRootShare is present."
        if( $Apply ) {
            if ($Ensure -ne 'Present'){
                try{
                    Write-Verbose -Message "Removing DFSNamespace $DFSRootShare"
                    Remove-DfsnRoot -Path "\\$DomainName\$DFSRootShare" -Force 
                    Write-Verbose -Message "DFSNamespace $DFSRootShare has been deleted"
                }
                catch {
                    Write-Error -Message 'Unhandled exception removing DFSNamespace'
                    throw $_                
                }
            }
        }
        Else{ 
            return ($Ensure -eq 'Present')
        }
    }
    Else {
        Write-Verbose -Message "DFSNamespace $DFSRootShare is absent."
        if($Apply) {
            if( $Ensure -ne 'Absent' ) {
                $params = @{ 
                    Path = "\\$DomainName\$DFSRootShare" 
		            Targetpath = "\\$DFSRootServer\$DFSRootShare"
		            Type = 'DomainV2'
                }
                try{
                    New-DfsnRoot @params
                    Write-Verbose -Message "DFSNamespace \\$DomainName\$DFSRootShare has been created"
                }
                catch {
                    Write-Error -Message 'Unhandled exception creating DFSNamespace'
                    throw $_                  
                }
            }
        }
        else {
            return ( $Ensure -eq 'Absent' )
        }
    }
}


Export-ModuleMember -Function *-TargetResource

