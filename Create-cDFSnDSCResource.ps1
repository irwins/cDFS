Import-Module xDSCResourceDesigner

#Define DSC parameters
$ResourceName = 'cDFSn'
$FriendlyName = 'cDFSnRoot'
$DomainName = New-xDscResourceProperty -Name DomainName -Type String -Attribute Required
$DFSRootServer = New-xDscResourceProperty -Name DFSRootServer -Type String -Attribute Key
$DFSRootShare = New-xDscResourceProperty -Name DFSRootShare -Type String -Attribute Required
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet 'Present', 'Absent'

# Create the DSC resource 
New-xDscResource `
   -Name "PSHOrg_$FriendlyName" `
   -Property $DomainName,$DFSRootServer,$DFSRootShare,$Ensure `
   -Path "C:\Program Files\WindowsPowerShell\Modules\$ResourceName" `
   -ClassVersion 1.0 `
   -FriendlyName $FriendlyName `
   -Force
