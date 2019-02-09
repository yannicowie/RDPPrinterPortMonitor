####PowerShell Script that tests the connection to all TCP/IP print server ports and then reports on those that are not available.

#Initialising the display list output
Write-Host "This script may take some time to complete as it needs to check each port"
pause
clear-host

#Getting lists of all printers and all TCP/IP ports on the computer
$allTCPIPports = Get-WMIObject win32_tcpipprinterport

$allPrinters = get-printer

$numberOfPorts = $allTCPIPports.length
$numberOfPrinters = $allPrinters.length

[array]$PortsInUseArray = @()
[array]$PrintersInUseArray = @()
[array]$DeadPrinters = @()

#function to carry out a test TCP connection to the printer port
function Port-Tester {
	
	#getting number of ports that we need to test
	$NumPortsToTest = $PortsInUseArray.length
	
	if ($testerCounter -lt $NumPortsToTest){
		#testing the ports one by one.
		$hostname = $PortsInUseArray[$testerCounter].HostAddress
		$portnum = $PortsInUseArray[$testerCounter].PortNumber
		
		$conntest = test-netconnection $hostname -Port $portnum
		
		$conntestresult = $conntest.TcpTestSucceeded
		
		if ($conntestresult = "False"){
			#the port is down, so we need to log the name of the printer and present that as the result of the script
			$printerdown = $PrintersInUseArray[$testerCounter].name
			$DeadPrinters = $DeadPrinters + $printerdown
			
			#now that we've notified the user the printer is down, we can move on and check the next printer in the list if there is one
			$testerCounter = $testerCounter + 1
			Port-Tester
		}
		else {
			#that was a good port, so increase the counter by one and trigger the function again
			$testerCounter = $testerCounter + 1
			Port-Tester
		}
	}
	
	else {
		#we must have tested all the ports, so time to finish the function
		clear-host
		write-host "List of printers that are dead:"
		write-host ""
		write-host $DeadPrinters -foregroundcolor red
		write-host ""
		write-host "The script has finished!"
	}
	
}

#function to check if we should add the port to the list of ports in use
function Port-In-Use {

		if ($portCounter -eq $numberOfPorts){
			#checking to see if we've tested all the ports for the printer we're on, and if we have, increasing the printerCounter and triggering the function again so we advance to testing the next printer.
			$printerCounter = $printerCounter + 1
			#resetting port counter so we can retest all the ports on the next printer
			$portCounter = 0
			Port-In-Use
		}
		elseif ($printerCounter -lt $numberOfPrinters){

			if ($allTCPIPports[$portCounter].Name -eq $allPrinters[$printerCounter].PortName){
				#this means the TCP/IP port is in use by a printer, so adding it to the list of ports in use.
				$PortsArrayElement = $allTCPIPports[$portCounter]
				$PortsInUseArray = $PortsInUseArray + $PortsArrayElement
				
				$PrintersArrayElement = $allPrinters[$printerCounter]
				$PrintersInUseArray = $PrintersInUseArray + $PrintersArrayElement
				
				#increasing the port counter so next time we can check the next port
				$portCounter = $portCounter + 1
				Port-In-Use
				
				
			}else {
			
			#the port we are testing isn't in use. Let's see if we can test the next one
			
				if ($portCounter -lt $numberOfPorts){
	
					#this would mean the next port does exist, so we should check it.
					$portCounter = $portCounter + 1
					Port-In-Use
					
				}else {
					
					#This would mean we've checked all the ports. Time for the next printer.
					$printerCounter = $printerCounter +1
					#we need to reset the port counter to check all the ports again
					$portCounter = 0
					Port-In-Use
				}
			}
		}else {
		

				#TESTING
				
				#we've checked all the printers. Job done!
				#clear-host
				#write-host "All TCP/IP Ports that are in use by a printer:"
				#write-host ""
				#write-host $PortsInUseArray[0].PortNumber
				#write-host ""
			
			##The $PortsInUseArray now contains a list of all the TCP/IP ports currently in use by printers and contains the properties "HostAddress" and "PortNumber" that can be passed through to the test-netconnection
			
			#triggering the next function, to test the TCP/IP connection to the ports
			Port-Tester
		}
}	

[int]$printerCounter = 0
[int]$portCounter = 0

[int]$testerCounter = 0

Port-In-Use	