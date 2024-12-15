#Logic: https://github.com/RamblingCookieMonster/PowerShell/blob/master/Get-SQLInstance.ps1
function Get-SQLInstance {
	[CmdletBinding()]
	Param (
		[parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
		[Alias('__Server','DNSHostName','IPAddress')]
		[string[]]$ComputerName = $env:COMPUTERNAME,
		
		[string]$InstanceName,

		[switch]$WMI
	) 
	Begin {
		$baseKeys = "SOFTWARE\\Microsoft\\Microsoft SQL Server",
			"SOFTWARE\\Wow6432Node\\Microsoft\\Microsoft SQL Server"
	}
	Process {
		$clusterProcess = $False
		ForEach ($Computer in $Computername) {
			
			$Computer = $computer -replace '(.*?)\..+','$1'
			Write-Verbose ("Processing Computer: {0}" -f $Computer)
			Write-Host ("Processing Computer: {0}" -f $Computer)
			
			$allInstances = foreach($baseKey in $baseKeys){
				Try {   
					$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer) 
					$regKey= $reg.OpenSubKey($baseKey)
					
					If ($regKey.GetSubKeyNames() -contains "Instance Names") {
						$regKey = $reg.OpenSubKey("$baseKey\\Instance Names\\SQL" ) 
						$instances = @($regkey.GetValueNames())
					}
					ElseIf ($regKey.GetValueNames() -contains 'InstalledInstances') {
						#$isCluster = $False
						$instances = $regKey.GetValue('InstalledInstances')
					}
					Else {
						Continue
					}
					If ($instances.count -gt 0) { 
						ForEach ($instance in $instances) {
							if ($InstanceName -and $instance -ne $InstanceName) {
								continue
							}
							
							$instanceValue = $regKey.GetValue($instance)
							$instanceReg = $reg.OpenSubKey("$baseKey\\$instanceValue")
							if ($clusterProcess){
								$nodes = New-Object System.Collections.Arraylist
								$clusterName = $Null
								$isCluster = $False
								if ($instanceReg.GetSubKeyNames() -contains "Cluster") {
									$isCluster = $True
									$instanceRegCluster = $instanceReg.OpenSubKey('Cluster')
									$clusterName = $instanceRegCluster.GetValue('ClusterName')
									$clusterReg = $reg.OpenSubKey("Cluster\\Nodes")                            
									$clusterReg.GetSubKeyNames() | ForEach-Object {
										$null = $nodes.Add($clusterReg.OpenSubKey($_).GetValue('NodeName'))
									}
								}
							}
							
							$instanceRegSetup = $instanceReg.OpenSubKey("Setup")
							Try {
								$edition = $instanceRegSetup.GetValue('Edition')
							} Catch {
								$edition = $Null
							}
							Try{
								$Collation = $instanceRegSetup.GetValue('Collation')
							}
							Catch {
								$Collation = $Null
							}
							Try {
								$SQLBinRoot = $instanceRegSetup.GetValue('SQLBinRoot')
							} Catch {
								$SQLBinRoot = $Null
							}
							Try {
								$ErrorActionPreference = 'Stop'
								$servicesReg = $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services")
								$serviceKey = $servicesReg.GetSubKeyNames() | Where-Object {
									$_ -match "$instance"
								} | Select-Object -First 1
								$service = $servicesReg.OpenSubKey($serviceKey).GetValue('ImagePath')
								$file = $service -replace '^.*(\w:\\.*\\sqlservr.exe).*','$1'
								$version = (Get-Item ("\\$Computer\$($file -replace ":","$")")).VersionInfo.ProductVersion
							} Catch {
								$Version = $instanceRegSetup.GetValue('Version')
							} Finally {
								$ErrorActionPreference = 'Continue'
							}

								$TCPPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceValue\MSSQLServer\SuperSocketNetLib\Tcp"
								$subdata = Get-ChildItem -Path $TCPPath
								
								# Retrieve the TCP port value from "IPAll"
								$ipAllProperties = Get-ItemProperty -Path "$TCPPath\IPAll"
								$ipAllTcpPort = $ipAllProperties.TcpPort

								# Initialize arrays to store IP addresses and TCP ports
								$SQLIPs = @()
								$SQLPorts = @()

								# Iterate over each subkey
								foreach ($subkey in $subdata) {
									$subkeyProperties = Get-ItemProperty -Path $subkey.PSPath

									# Check if both Active and Enabled are true
									if ($subkeyProperties.Active -eq $true) {
										$ipAddress = $subkeyProperties.IPAddress
										# Check if the IP address is not localhost (127.0.0.1) or IPv6
										if ($ipAddress -ne "127.0.0.1" -and $ipAddress -notmatch '::') {
											# Check if the IP address is IPv4
											if ($ipAddress -match '\b(?:\d{1,3}\.){3}\d{1,3}\b') {
												# Retrieve the IPv4 address and TCP port
												$tcpPort = $subkeyProperties.TcpPort
												if ([string]::IsNullOrWhiteSpace($tcpPort)) {
													$tcpPort = $ipAllTcpPort
												}
												$tcpEnabled = $subkeyProperties.Enabled
												$tcpStatus = if ($tcpEnabled -eq 1) { "YES" } else { "NO" }
												#Write-Host "Debug TCPIP Status: $($tcpStatus)"
												# Add the IP address and TCP port to the arrays
												$SQLIPs += $ipAddress
												$SQLPorts += $tcpPort

											}
										}
									}
								}

								# Output the IPv4 addresses and corresponding TCP ports
								for ($i = 0; $i -lt $SQLIPs.Count; $i++) {
									#Write-Host "IP Address: $($SQLIPs[$i]), TCP Port: $($SQLPorts[$i])"
								}

							New-Object PSObject -Property @{
								Computername = $Computer
								SQLInstance = $instance
								SQLBinRoot = $SQLBinRoot
								Edition = $edition
								Version = $version
								FullInstance = $instanceValue
								Caption = {Switch -Regex ($version) {
									"^16" {'SQL Server 2022';Break}
									"^15" {'SQL Server 2019';Break}
									"^14" {'SQL Server 2017';Break}
									"^13" {'SQL Server 2016';Break}
									"^12" {'SQL Server 2014';Break}
									"^11" {'SQL Server 2012';Break}
									"^10\.5" {'SQL Server 2008 R2';Break}
									"^10" {'SQL Server 2008';Break}
									"^9"  {'SQL Server 2005';Break}
									"^8"  {'SQL Server 2000';Break}
									"^7"  {'SQL Server 7.0';Break}
									Default {'Unknown Version'}
								}}.InvokeReturnAsIs()
								Collation = $Collation
								isCluster = $isCluster
								TCPEnabled = $tcpStatus
								isClusterNode = ($nodes -contains $Computer)
								ClusterName = $clusterName
								ClusterNodes = ($nodes -ne $Computer) 
								FullSQLName = {
									If ($Instance -eq 'MSSQLSERVER') {
										$Computer
									} Else {
										"$($Computer)\$($instance)"
									}
								}.InvokeReturnAsIs()
								IPAddress = $SQLIPs
								SQLPort = $SQLPorts
							}
						}
					}
                    
				} Catch { 
					Write-Warning ("Someting Wrong: {0}: {1}" -f $Computer,$_.Exception.Message)
				}
			}

			if($WMI){
				Try{
					$sqlServices = $null
					$sqlServices = @(
						Get-WmiObject -ComputerName $computer -query "select DisplayName, Name, PathName, StartName, StartMode, State from win32_service where Name LIKE 'MSSQL%'" -ErrorAction stop  |
						Where-Object {$_.Name -match "^MSSQL(Server$|\$)"} |
						Select-Object DisplayName, Name,StartName, StartMode, State, PathName
					)

					if($sqlServices){
						Write-Verbose "WMI Service info:`n$($sqlServices | Format-Table -AutoSize -Property * | out-string)"
						foreach($inst in $allInstances){
							$matchingService = $sqlServices |
							Where-Object {$_.pathname -like "$( $inst.SQLBinRoot )*" -or $_.pathname -like "`"$( $inst.SQLBinRoot )*"} |
							Select-Object -First 1

							$inst | Select-Object -property Computername,
							SQLInstance,
							SQLBinRoot,
							Edition,
							Version,
							Caption,
							FullInstance,
							isCluster,
							isClusterNode,
							ClusterName,
							ClusterNodes,
							FullSQLName,
							IPAddress,
							SQLPort,
							TCPEnabled,
							Collation,
							@{ label = "ServiceDisName"; expression = {
								if($matchingService){
									$matchingService.DisplayName
								}
								else{"No WMI Match"}
							}},
							@{ label = "ServiceName"; expression = {
								if($matchingService){
									$matchingService.Name
								}
								else{"No WMI Match"}
							}},
							@{ label = "ServiceState"; expression = {
								if($matchingService){
									$matchingService.State
								}
								else{"No WMI Match"}
							}},
							@{ label = "ServiceAccount"; expression = {
								if($matchingService){
									$matchingService.startname
								}
								else{"No WMI Match"}
							}},
							@{ label = "ServiceStartMode"; expression = {
								if($matchingService){
									$matchingService.startmode
								}
								else{"No WMI Match"}
							}}
						}
					}
				}
				Catch {
					Write-Warning "Could not retrieve WMI info for '$computer':`n$_"
					$allInstances
				}

			}
			else {
				$allInstances 
			}
		}   
	}
} ## END function Get-SQLInstance


# Call Get-SQLInstance function to retrieve SQL instance information
$sqlInstances = Get-SQLInstance -WMI

# Assuming $sqlInstances contains multiple objects, you can access their properties like this:
foreach ($instance in $sqlInstances) {
	$ComputerName = $instance.Computername
	$SQLInstance = $instance.SQLInstance
	$FullSQLName = $instance.FullSQLName
	$FullInstance = $instance.FullInstance
	$IPAddress = $instance.IPAddress
	$SQLPort = $instance.SQLPort
	$tcpEnabled = $instance.TCPEnabled
	$SQLBinRoot = $instance.SQLBinRoot
	$Edition = $instance.Edition
	$Collation = $instance.Collation
	$Version = $instance.Version
	$Caption = $instance.Caption
	$isCluster = $instance.isCluster
	$isClusterNode = $instance.isClusterNode
	$ClusterName = $instance.ClusterName
	$ServiceName = $instance.ServiceName
	$ServiceState = $instance.ServiceState
	$ServiceDisName = $instance.ServiceDisName
	$ServiceAccount = $instance.ServiceAccount
	$ServiceStartMode = $instance.ServiceStartMode
    
    # Now you can use these variables as needed
	Write-Host "Computer Name:			$COMPUTERNAME"
	Write-Host "SQL Instance:			$SQLInstance"
	Write-Host "Full SQL Server Name:	$FullSQLName"
	Write-Host "Full Instance: 			$FullInstance"
	Write-Host "SQL IP Address:			$IPAddress"
	Write-Host "SQL Port:				$SQLPort"
	Write-Host "TCP/IP Enabled:			$tcpEnabled"
	Write-Host "SQLBinRoot:				$SQLBinRoot"
	Write-Host "Edition: 				$Edition"
	Write-Host "Version: 				$Version"
	Write-Host "Collation: 				$Collation"
	Write-Host "Caption: 				$Caption"
	if ($clusterProcess){
	Write-Host "Is Cluster: 			$isCluster"
	Write-Host "Is Cluster Node: 		$isClusterNode"
	Write-Host "Cluster Name: 			$ClusterName"
	}
	Write-Host "Service Name:			$ServiceName"
	Write-Host "Service State: 			$ServiceState"
	Write-Host "Service Display Name:	$ServiceDisName"
	Write-Host "Service Account: 		$ServiceAccount"
	Write-Host "Service Start Mode:		$ServiceStartMode"
}