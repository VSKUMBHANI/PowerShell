# Script is return the subnet mask in xxx.xxx.xxx.xxx format.
# https://github.com/VSKUMBHANI/PowerShell

Function Get-NetworkIPv4 {
    param(
        [string]$ipAddress,
        [int]$cidr
    )
    $parsedIpAddress = [System.Net.IPAddress]::Parse($ipAddress)
    $shift = 64 - $cidr
    
    [System.Net.IPAddress]$subnet = 0

    if ($cidr -ne 0) {
        $subnet = [System.Net.IPAddress]::HostToNetworkOrder([int64]::MaxValue -shl $shift)
    }

    [System.Net.IPAddress]$network = $parsedIpAddress.Address -band $subnet.Address

    return [PSCustomObject]@{
        Network = $network
        SubnetMask = $subnet
    }
}
# Get the IP address assigned to the network adapter 'ethernet'. Replace it with your adapter alias.
$ipAlias = Get-NetIPAddress | Where-Object {$_.InterfaceAlias -eq "ethernet"}
$NetipAddress = $ipAlias.IPAddress
$subnetPrefix = $ipAlias.PrefixLength

$ipDetails = Get-NetworkIPv4 -ipAddress $NetipAddress -cidr $subnetPrefix

# Get Subnet string.
$subnetmask = $ipDetails.SubnetMask.IPAddressToString
$subnetmask
