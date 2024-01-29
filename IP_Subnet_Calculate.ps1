<# 
# Calculate the subnet and get details of ip range with class.
# https://github.com/VSKUMBHANI/PowerShell

Example
Get-Subnet -IP 192.168.1.10/24
#>
Function Get-Subnet {
    param ( 
        [parameter(ValueFromPipeline)]
        [String]
        $IP,

        [ValidateRange(0, 32)]
        [int]
        $MaskBits,

        [switch]
        $SkipHosts
    ) 
    Begin {
        Function Convert-IPtoINT64 ($ip) { 
            $octets = $ip.split(".") 
            [int64]([int64]$octets[0] * 16777216 + [int64]$octets[1] * 65536 + [int64]$octets[2] * 256 + [int64]$octets[3]) 
        } 
 
        Function Convert-INT64toIP ([int64]$int) { 
            (([math]::truncate($int / 16777216)).tostring() + "." + ([math]::truncate(($int % 16777216) / 65536)).tostring() + "." + ([math]::truncate(($int % 65536) / 256)).tostring() + "." + ([math]::truncate($int % 256)).tostring() )
        } 

        If (-not $IP -and -not $MaskBits) { 
            $LocalIP = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -ne 'WellKnown'})

            $IP = $LocalIP.IPAddress
            $MaskBits = $LocalIP.PrefixLength
        }
    }
    Process {
        If ($IP -match '/\d') { 
            $IPandMask = $IP -Split '/' 
            $IP = $IPandMask[0]
            $MaskBits = $IPandMask[1]
        }
        
        $IPAddr = [Net.IPAddress]::Parse($IP)

        $Class = Switch ($IP.Split('.')[0]) {
            {$_ -in 0..127} { 'A' }
            {$_ -in 128..191} { 'B' }
            {$_ -in 192..223} { 'C' }
            {$_ -in 224..239} { 'D' }
            {$_ -in 240..255} { 'E' }
            
        }
        
        If (-not $MaskBits) {
            $MaskBits = Switch ($Class) {
                'A' { 8 }
                'B' { 16 }
                'C' { 24 }
                default { Throw 'Subnet mask size was not specified and could not be inferred.' }
            }

            Write-Warning "Subnet mask size was not specified. Using default subnet size for a Class $Class network of /$MaskBits."
        }

        If ($MaskBits -lt 16 -and -not $SkipHosts) {
            Write-Warning "It may take some time to calculate all host addresses for a /$MaskBits subnet. Use -SkipHosts to skip."
        }
    
        $MaskAddr = [Net.IPAddress]::Parse((Convert-INT64toIP -int ([convert]::ToInt64(("1" * $MaskBits + "0" * (32 - $MaskBits)), 2))))
        
        $NetworkAddr = New-Object net.ipaddress ($MaskAddr.address -band $IPAddr.address) 
        $BroadcastAddr = New-Object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $MaskAddr.address -bor $NetworkAddr.address))
     
        $HostStartAddr = (Convert-IPtoINT64 -ip $NetworkAddr.ipaddresstostring) + 1
        $HostEndAddr = (Convert-IPtoINT64 -ip $broadcastaddr.ipaddresstostring) - 1
        
        If (-not $SkipHosts) {
            $HostAddresses = for ($i = $HostStartAddr; $i -le $HostEndAddr; $i++) {
                Convert-INT64toIP -int $i
            }
        }

    
        [pscustomobject]@{
            IPAddress        = $IPAddr
            MaskBits         = $MaskBits
            NetworkAddress   = $NetworkAddr
            BroadcastAddress = $broadcastaddr
            SubnetMask       = $MaskAddr
            NetworkClass     = $Class
            Range            = "$networkaddr ~ $broadcastaddr"
            HostAddresses    = $HostAddresses
        }
    }
    End {}
}

Get-Subnet -IP 192.168.1.3/21
