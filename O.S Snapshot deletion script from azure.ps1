<#
    Run this script with PowerShell 5.1 and provide identity access (Contributor access) to resource level or subscription level

    .NOTES
        AUTHOR: VG SaaS
        LASTEDIT: Sep 15, 2023
	Deletes only snapshots with "maintenance" in the name and older than the specified threshold.
#>

try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Get all ARM resources from all resource groups
$ResourceGroups = Get-AzResourceGroup

foreach ($ResourceGroup in $ResourceGroups)
{   
    $thresholdDate = (Get-Date).AddDays(-7)  # Set the threshold date to 7 days ago

    # Get snapshots in the specified resource group
    $location = $ResourceGroup.Location
    $RG = $ResourceGroup.ResourceGroupName

    $snapshots = Get-AzSnapshot -ResourceGroupName $RG

    # Display information about the snapshots, including created time
    foreach ($snapshot in $snapshots)          
    {
        $snapshotDetails = Get-AzResource -ResourceId $snapshot.Id -ApiVersion "2019-03-01"
        $createdTime = [DateTime]::Parse($snapshotDetails.Properties.timeCreated)

        if ($createdTime -lt $thresholdDate -and $snapshot.Name -like "*maintenance*") 
        {
            Write-Output "Deleting snapshot: $($snapshot.Name)"
            Remove-AzSnapshot -ResourceGroupName $RG -SnapshotName $snapshot.Name -Force
        }
    }
}
