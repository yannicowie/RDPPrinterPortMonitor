####PowerShell Script that tests the connection to all TCP/IP print server ports and then reports on those that are not available.

#NEED TO clear the log file - still a work in progress


#Getting list of all print ports on the server
$allPorts = Get-WMIObject win32_tcpipprinterport
$portCount = $allPorts.length

$global:DeadPorts = $false

function Port-Tester{

	#Doing a TCP connection test to the port if the number of ports to count is less than the number that have already been counted.
	if ($counter -lt $portCount){
	
		$IPAddress = $allPorts[$counter].HostAddress
		$PortNumber = $allPorts[$counter].PortNumber
		
		$testConnection = test-netconnection $IPAddress -Port $PortNumber

		$PortLive = $testConnection.TcpTestSucceeded
		$ComputerName = $env:computername
		$PortName = $allPorts[$counter].Name
		
		#If the TCP connection test to the port fails, writing this to the log file
		if ($PortLive = "False"){
		
			$logline = "On " + $ComputerName + " Port Name " + $PortName + " is down. Trying to connect to " + $IPAddress + " -port " + $PortNumber
			$logline | Out-File portlog.txt -Append -Encoding ASCII
		
			$global:DeadPorts = $true
			
		}
		
		#Adding +1 to the $counter
		$counter = $counter + 1
		#Triggering the function again to run the test on the next port
		Port-Tester
	}
	
	#If all ports have been tested, announce completion
	else {
	
		write-host "Port test has finished"
		
		#Announcing if there were any TCP ports that a connection couldn't be established to.
		if ($global:DeadPorts = $true){write-host "There are some dead ports!"}
	}
}

#Initialising the $counter variable and setting it to 0 (i.e. no ports counted yet)
$counter = 0
#Triggering the port testing function
Port-Tester