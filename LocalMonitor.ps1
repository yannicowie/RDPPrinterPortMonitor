####PowerShell Script that tests the connection to all TCP/IP print server ports and then reports on those that are not available.

function Check-Servers {

	param($ServerName)

	#Getting lists of all printers and all TCP/IP ports on the computer
	$allTCPIPports = Get-WMIObject win32_tcpipprinterport -ComputerName $ServerName

	$allPrinters = get-printer -ComputerName $ServerName

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
			
				#test-netconnection needs to be run on the server the port is set up on becasue it needs to come from that server's external IP - some printer ports may be locked down to only accept connections from the server's IP
				$conntest = Invoke-Command $ServerName {test-netconnection $hostname -Port $portnum}
			
			$conntestresult = $conntest.TcpTestSucceeded
			
			#TESTING - a progress indication to say that a printer has been tested
			write-host "A printer has been tested"
			
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
			#we must have tested all the ports, so time to finish the function by writing the dead printers to the log file
			
			function line-writer {
				$NumOfDeadPrinters = $DeadPrinters.length
				$lineCounter = 0
				if ($lineCounter -lt $NumOfDeadPrinters){
					$lineToWrite = $ServerName + ": " + $DeadPrinters[$lineCounter].name
					$lineToWrite | Out-File $logfilepathname
					#We've now written that printer to the list, increasing line counter by one and triggering the function again
					$lineCounter = $lineCounter + 1
					line-writer
				}
			}
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
				
				##The $PortsInUseArray now contains a list of all the TCP/IP ports currently in use by printers and contains the properties "HostAddress" and "PortNumber" that can be passed through to the test-netconnection
				
				#triggering the next function, to test the TCP/IP connection to the ports
				Port-Tester
			}
	}	

	[int]$printerCounter = 0
	[int]$portCounter = 0

	[int]$testerCounter = 0

	Port-In-Use	
}

function Get-Servers {
	$ServerList = Get-ADComputer -Filter *
	$NumberOfServers = $ServerList.length
	
	$serverCounter = 0
	
	if ($serverCounter -lt $NumberOfServers) {
		$currentServerName = $ServerList[$serverCounter].name
		
		#triggering the Check-Servers function and passing it the computer name parameter
		$serverCounter = $serverCounter + 1
		Check-Servers -ServerName $currentServerName
		
		#TESTING - a progress indication to say when a server is done
		write-host "A server has ben completed"
	}
	else {
		#all of the servers have been checked, so completing script
		#insert action on script completion here
		
		#TESTING - a progress indication to say when the script has completed
		write-host "All networked pritners on all servers have been checked. Output has been saved to log"
	}
}

function Do-LogFile {
	#Creating LogFile with today's date in file name
	$currentDateTime = get-date -UFormat "%d-%m-%Y - %H:%M"
	$logfilename = "PrinterPortLog " + $currentDateTime + ".txt"
	$logfilepath = "C:\PrinterLogging\Logs"
	$global:logfilepathname = $logfilepath + "\" + $logfilename
	
	New-Item -Path $logfilepath -Name $logfilename
}

Do-LogFile

Get-Servers