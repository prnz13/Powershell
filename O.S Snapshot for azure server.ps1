<#
  	  Run this script with Powershell 5.1 and provide identity access (Conrtibutor access) to resouce level or subscription level

    .NOTES
        AUTHOR: Prince
        LASTEDIT: Apr 04, 2024
	
	Using this script we can create O.S Snapshots. 
	please change Tagname and Tag value with the server Tag name and Value. 
	Tag name of the newly created Snapshot would be "Maintenance" and the value will be "DEV & VAL"

#>

try {
    "Logging in to Azure..."
    Connect-AzAccount -Identity
} catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Get all ARM resources with specific tags
$tagname = "Maintenance"
$tagvalue = "DEV & VAL"
$taglist = Get-AzResource -TagName $tagname -TagValue $tagvalue

# Output the header
$header = "Resource Name", "Resource Type", "Location", "Resource Group"
$headerOutput = "{0,-50} {1,-30} {2,-15} {3,-15}" -f $header
Write-Output $headerOutput

foreach ($tag in $taglist) {
    $output = "{0,-50} {1,-25} {2,-20} {3,-15}" -f $tag.Name, $tag.ResourceType, $tag.Location, $tag.ResourceGroupName
    Write-Output $output

    if ($tag.ResourceType -eq "Microsoft.Compute/virtualMachines") {
        $vm = Get-AzVM -ResourceGroupName $tag.ResourceGroupName -Name $tag.Name

        if ($vm) {
            $timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss
            $Maintenancename = "_Maintenance_OS_Snapshot_"
            $snapshotName = $vm.Name + $Maintenancename + $timestamp
            $snapshot = New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $tag.Location -CreateOption copy -Tag @{Maintenance="true"}
            New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $tag.ResourceGroupName
        } else {
            Write-Host "Failed to retrieve VM: $($tag.Name)"
        }
    } else {
        Write-Host "$($tag.ResourceId) is not a compute instance"
    }
}
