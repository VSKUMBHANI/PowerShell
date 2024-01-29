<#
#A PowerShell script that will provide you the Regex syntax for matching an IP range of currnet 'ethernet' adapter
#Verify the regex on https://regex101.com/ for cross check.
#https://github.com/VSKUMBHANI/PowerShell/
#>
# Get the IP address assigned to the network adapter 'ethernet'
$ipAlias = Get-NetIPAddress | Where-Object {$_.InterfaceAlias -eq "ethernet"}
$NetipAddress = $ipAlias.IPAddress
$subnetPrefix = $ipAlias.PrefixLength

$ipAddSub = $NetipAddress + '/' + $subnetPrefix

[Parameter()]
[string]$IPRange = $ipAddSub

#########################
# IP SUBNET MATH Functions 
# Borrowed from Mark Gossa 
# https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Subnet-db45ec74#content
#######################################################################################

function Get-IPs { 
 
        Param( 
        [Parameter(Mandatory = $true)] 
        [array] $Subnets 
        ) 
 
foreach ($subnet in $subnets) 
    { 
         
        #Split IP and subnet 
        $IP = ($Subnet -split "\/")[0] 
        $SubnetBits = ($Subnet -split "\/")[1] 
         
        #Convert IP into binary 
        #Split IP into different octects and for each one, figure out the binary with leading zeros and add to the total 
        $Octets = $IP -split "\." 
        $IPInBinary = @() 
        foreach($Octet in $Octets) 
            { 
                #convert to binary 
                $OctetInBinary = [convert]::ToString($Octet,2) 
                 
                #get length of binary string add leading zeros to make octet 
                $OctetInBinary = ("0" * (8 - ($OctetInBinary).Length) + $OctetInBinary) 
 
                $IPInBinary = $IPInBinary + $OctetInBinary 
            } 
        $IPInBinary = $IPInBinary -join "" 
 
        #Get network ID by subtracting subnet mask 
        $HostBits = 32-$SubnetBits 
        $NetworkIDInBinary = $IPInBinary.Substring(0,$SubnetBits) 
         
        #Get host ID and get the first host ID by converting all 1s into 0s 
        $HostIDInBinary = $IPInBinary.Substring($SubnetBits,$HostBits)         
        $HostIDInBinary = $HostIDInBinary -replace "1","0" 
 
        #Work out all the host IDs in that subnet by cycling through $i from 1 up to max $HostIDInBinary (i.e. 1s stringed up to $HostBits) 
        #Work out max $HostIDInBinary 
        $imax = [convert]::ToInt32(("1" * $HostBits),2)  
        

 
        $IPs = @() 
 
        #Next ID is first network ID converted to decimal plus $i then converted to binary 
        For ($i = 0 ; $i -le $imax ; $i++) 
            { 
                #Convert to decimal and add $i 
                $NextHostIDInDecimal = ([convert]::ToInt32($HostIDInBinary,2) + $i) 
                #Convert back to binary 
                $NextHostIDInBinary = [convert]::ToString($NextHostIDInDecimal,2) 
                #Add leading zeros 
                #Number of zeros to add  
                $NoOfZerosToAdd = $HostIDInBinary.Length - $NextHostIDInBinary.Length 
                $NextHostIDInBinary = ("0" * $NoOfZerosToAdd) + $NextHostIDInBinary 
 
                #Work out next IP 
                #Add networkID to hostID 
                $NextIPInBinary = $NetworkIDInBinary + $NextHostIDInBinary 
                #Split into octets and separate by . then join 
                $IP = @() 
                For ($x = 1 ; $x -le 4 ; $x++) 
                    { 
                        #Work out start character position 
                        $StartCharNumber = ($x-1)*8 
                        #Get octet in binary 
                        $IPOctetInBinary = $NextIPInBinary.Substring($StartCharNumber,8) 
                        #Convert octet into decimal 
                        $IPOctetInDecimal = [convert]::ToInt32($IPOctetInBinary,2) 
                        #Add octet to IP  
                        $IP += $IPOctetInDecimal 
                    } 
 
                #Separate by . 
                $IP = $IP -join "." 
                $IPs += $IP 
            
                 
            } 
        #$IPs
        Return @($($IPs[0]),$($IPs[-1]))

    } 
} 

#########################
# REGEX FUNCTIONS
###########################

#Translated to PowerShell from code by Hansott
#https://github.com/hansott/range-regex/blob/master/src/ConverterDefault.php

Function splitToRanges($min,$max)
{

$Nines=1
$Stops=@()
$Stops+=$max
$Stop=CountNines -num $min -nines $nines

#write-host "debug Entry: $min $max stop: $Stop"

    while ( ($min -le $stop ) -and ( $stop -le $max) ) {

        if ($stops -notcontains $stop){

            $stops+=$stop
            #write-host "debug Nines: min $min max $max stop $stop"
        }

        $nines++
        $stop=countNines -num $min -nines $nines

    } #endwhile

    $Zeros = 1 
    $stop = (countZeros -integer ($max+1) -zeros $zeros)-1

    while ( ($min -lt $stop ) -and ( $stop -le $max) ) {

        if ($stops -notcontains $stop){

            $stops+=$stop
            #write-host "debug zeros: min $min max $max stop $stop"
        }

     $Zeros += 1
    $stop = (countZeros -integer ($max+1) -zeros $zeros)-1
    }
    
    $stops=$stops|Sort-Object
    $Stops 


}

Function splitToPatterns ($min, $max) {

$start=$min
$subPatterns = @()
$Ranges=@()

$Ranges= splitToRanges -min $min -max $max

    $Ranges | ForEach-Object  {

    $subPatterns+= rangeToPattern -start $start -stop $_
    $start = $_ +1

   }

$subPatterns

}

function siftPatterns($negatives, $positives) {

$onlyNegative = @()
$onlyPositives = @()

$onlyNegative = filterPatterns -arr $negatives -comparison $positives -prefix "-" -intersection $false
$onlyPositives = filterPatterns -arr $positives -comparison $negatives  -prefix "" -intersection $false
$intersected = filterPatterns -arr $negatives -comparison $positives -prefix "-?" -intersection $true
$subPatterns = $onlyNegative + $intersected + $onlyPositives

$subpatterns -join "|"

}

function filterPatterns ($arr,$comparison,$prefix,$intersection) {

$intersected = @()
$result = @()

$arr | foreach {

    if (($intersection -eq $false) -and ($comparison -notcontains $_) ){
    
        $result+= $prefix.tostring() + $_.tostring()

    }

    if (($intersection) -and ($comparison -contains $_) ){
    
        $intersected+= $prefix.tostring() + $_.tostring()

    }
    } #endforeach

    if ($intersection) { $intersected } else { $result }

}

function rangeToPattern($start, $stop)  {

        $pattern = ''
        $digits = 0
        $pairs=@()
        $pairs = zip -start $start -stop $stop

       #If foreach is not used this way, then continue acts as a break
       foreach ($_ in $pairs) {
            $startDigit = $_[0];
            $stopDigit = $_[1];

            if ($startDigit -eq $stopDigit) {
                $pattern += $startDigit
                continue
            }
            if (($startDigit -ne '0') -or ($stopDigit -ne '9')) {
                $pattern += "[$startDigit-$stopDigit]"
                continue
            }
            $digits++;
        }
        if ($digits -gt 0) {
            $pattern += '[0-9]';
        }
        if ($digits -gt 1) {
            $pattern += "{$digits}"
        }
        return $pattern;
}

 function countNines($num, $nines) {

        
        $num = [string]$num
        
        $offset = -1 * $nines; 
        
        $result=enhancedSubstring -string $num -start 0 -offset $offset  
        
        return [int] ($result + $('9'* $nines));
    
 }


function countZeros($integer, $zeros) {
        # the % is modulus (reminder)
        # Integer mod (10*number of zeros)
        # take the result of that and remove it from integer and send it back
        # 227 - ( 227 mod 220) 
        return $integer - ($integer % [math]::pow(10, $zeros));
}

 function zip($start, $stop) {

        $start = $start.tostring();
        $stop = $stop.tostring();
        $start = $start.ToCharArray()
        $stop = $stop.ToCharArray()
        $zipped = @();
        $index=0

        $start | foreach {
            
            $zipped+=,@($_, $stop[$index])            
            $index++
        }

        return ,$zipped;

}

function enhancedSubstring ($string, $start, [int]$offset) {
    
    #Check for an invalid offset
    if ($string.length -lt [math]::abs($offset)) { return ""}

    if ($offset -lt 0 ) {
    #Enhanced behavior to match php's mb_string
        
        $temp= $string.substring($start,$string.Length-$start)
        
        return $temp.substring(0,$temp.length+$offset)

    } else {
    #Regular PowerShell Substring Behavior
        write-host "Entering non zero"
        return $string.substring($start, $offset)
    }

}

function RangeToRegex ([int]$min,[int]$max){

if ($min -ge $max) { "Min cannot be bigger or equal than Max";Return }

$Positives=@()
$Negatives=@()

if ($min -lt 0) {

    $newMin=1
    if ($max -lt 0) { $newMin=[math]::abs($max) }

    $newMax=[math]::abs($min)
    $Negatives = splitToPatterns -min $newMin -max $newMax
    $min=0
}



if ($max -ge 0) {
    $positives = splitToPatterns -min $min -max $max
}
$myResult= siftPatterns -negatives $negatives -positives $positives
$myResult
#endregion
}



function GetIPRegex ($IPRange) {

    $Regex = "\b"
    $Index=0
    $OctectsMin = $IPRange[0] -split "\."
    $OctectsMax = $IPrange[1] -split "\."
   
    #\bONE.\TWO\.THREE\.FOUR\b


   $octectsMin | foreach {
        
        if ($_ -eq $OctectsMax[$index]) {
            $Regex+="$_"
        } else {
            $Regex+="($(RangeToRegex -min $_ -max $OctectsMax[$index]))"
        }
        $index++
        if ($index -eq 4) { $Regex+="\b" } else { $Regex+="\." }
   }

   Return $Regex

}

Switch -Wildcard ($IPRange) {

    # IP range in format 192.168.10.1-192.168.10.20
    "*-*" { $RegexRule=GetIPRegex -IPRange ($IPRange -split "-") }

    # IP range in CDIR format 192.168.10.1/24
    "*/*"  { $RegexRule=GetIPRegex -IPRange $(Get-IPS -subnet $IPRange) }

    #Assume single IP
    default  { $RegexRule=GetIPRegex -IPRange $IPRange,$IPRange}


}

Write-Host "IP Range: $IPRange"
Write-Host "Matched Regex: $RegexRule"
