####PowerShell Script that tests the connection to all TCP/IP print server ports and then reports on those that are not available.

#NEED TO clear the log file - still a work in progress


#Getting list of all print ports on the server
$allPorts = Get-WMIObject win32_tcpipprinterport
$portCount = $allPorts.length

$global:DeadPorts = $false

function Port-Tester{
	if ($counter -lt $portCount){
	
		$IPAddress = $allPorts[$counter].HostAddress
		$PortNumber = $allPorts[$counter].PortNumber
		
		$testConnection = test-netconnection $IPAddress -Port $PortNumber

		$PortLive = $testConnection.TcpTestSucceeded
		$ComputerName = $env:computername
		$PortName = $allPorts[$counter].Name
		
		if ($PortLive = "False"){
		
			$logline = "On " + $ComputerName + " Port Name " + $PortName + " is down. Trying to connect to " + $IPAddress + " -port " + $PortNumber
			$logline | Out-File portlog.txt -Append -Encoding ASCII
		
			$global:DeadPorts = $true
			
		}
			
		$counter = $counter + 1
		#Triggering the function again to run the test on the next port
		Port-Tester
	}
	
	else {
	
		write-host "Port test has finished"
		
		if ($global:DeadPorts = $true){
			write-host "There are some dead ports!"
		}
	}
}

$counter = 0
Port-Tester