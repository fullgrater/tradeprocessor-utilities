#Retrieve connection details from the command line arguments.
#Originally this is arguments passing from the Zabbix-server via macros

$server=$args[0]
$username=$args[1]
$password=$args[2]

#Define URLs and body of the authorization request

$loginstr=$server+"api/auth/login"
$telemetrystr=$server+"api/telemetry"
$body = @{
"username" = $username;
"password" = $password
}

#Collect JWT Bearer and add it to the telemetry request in the authorization header

$jwt = ((Invoke-WebRequest $loginstr -Body $body -Method POST -UseBasicParsing).Content | ConvertFrom-json).jwt
$headers = @{Authorization = "Bearer $jwt"}

#Collect telemetry data and convert it to the PowerShell Object

$jsoninit = (Invoke-WebRequest $telemetrystr -Method GET -Headers $headers -UseBasicParsing).Content
$json = $jsoninit | ConvertFrom-json

#Create new PowerShell object that we will use to rearrange telemetry data structure for using in Zabbix

$Metrics = [PSCustomObject]@{}
$Metrics | Add-Member -MemberType NoteProperty -Name Gateway -Value @{'State'=$json.Gateways.State}

##################################___MT4___##################################

$Metrics | Add-Member -MemberType NoteProperty -Name MT4Connector -Value @{}
$i = 0 	#I'm pretty sure that this is not the best way possible to handle loop counter, 
		#but this little trick helps me to easilly deal with any numbers of the connectors in the list
foreach ($name in $json.Gateways.Mt4Connectors) {
	$connectorname = $json.Gateways.Mt4Connectors[$i].Name
	$Metrics.Mt4Connector[$connectorname] = @{}
		$Metrics.Mt4Connector.$connectorname['State'] = $json.Gateways.Mt4Connectors[$i].State
		$Metrics.Mt4Connector.$connectorname['RMQ'] = @{}
			$Metrics.Mt4Connector.$connectorname.RMQ['State'] = $json.Gateways.Mt4Connectors[$i].RabbitMQConnectionState
		$Metrics.Mt4Connector.$connectorname['Session'] = @{}
		$ii = 0  	#Another loop for sessions list. There can be any number of the sessions on each connector,
					#so we want to be sure that all of them will be processed by the script
		foreach ($session in $json.Gateways.Mt4Connectors[$i].Sessions) {
			$sessionname = $json.Gateways.Mt4Connectors[$i].Sessions[$ii].Name
			$Metrics.Mt4Connector.$connectorname.Session[$sessionname] = @{}
				$Metrics.Mt4Connector.$connectorname.Session.$sessionname['State'] = $json.Gateways.Mt4Connectors[$i].Sessions[$ii].State
			$session=$session
			$ii += 1
			}
	$name=$name
	$i += 1
	}
	
##################################___MT5___##################################

$Metrics | Add-Member -MemberType NoteProperty -Name MT5Connector -Value @{}
$i = 0
foreach ($name in $json.Gateways.Mt5Connectors) {
	$connectorname = $json.Gateways.Mt5Connectors[$i].Name
	$Metrics.Mt5Connector[$connectorname] = @{}
		$Metrics.Mt5Connector.$connectorname['State'] = $json.Gateways.Mt5Connectors[$i].State
		$Metrics.Mt5Connector.$connectorname['ManAPI'] = @{}
			$Metrics.Mt5Connector.$connectorname.ManAPI['State'] = $json.Gateways.Mt5Connectors[$i].ManagerApiState
		$Metrics.Mt5Connector.$connectorname['GateAPI'] = @{}
			$Metrics.Mt5Connector.$connectorname.GateAPI['State'] = $json.Gateways.Mt5Connectors[$i].GatewayApiState
	$name=$name
	$i += 1
	}
	
##################################___FIX___##################################

$Metrics | Add-Member -MemberType NoteProperty -Name FixConnector -Value @{}
$i = 0
foreach ($name in $json.Gateways.FixConnectors) {
	$connectorname = $json.Gateways.FixConnectors[$i].Name
	$Metrics.FixConnector[$connectorname] = @{}
		$Metrics.FixConnector.$connectorname['State'] = $json.Gateways.FixConnectors[$i].State
		$Metrics.FixConnector.$connectorname['Session'] = @{}
		$ii = 0
		foreach ($session in $json.Gateways.FixConnectors[$i].Sessions) {
			$sessionname = $json.Gateways.FixConnectors[$i].Sessions[$ii].Name
			$Metrics.FixConnector.$connectorname.Session[$sessionname] = @{}
				$Metrics.FixConnector.$connectorname.Session.$sessionname['State'] = $json.Gateways.FixConnectors[$i].Sessions[$ii].State
			$session=$session
			$ii += 1
			}
	$name=$name
	$i += 1
	}
	
################################___Coverage___###############################

$Metrics | Add-Member -MemberType NoteProperty -Name Coverage -Value @{}
$i = 0
foreach ($name in $json.Gateways.MtExecConnectors) {
	$connectorname = $json.Gateways.MtExecConnectors[$i].Name
	$Metrics.Coverage[$connectorname] = @{}
		$Metrics.Coverage.$connectorname['State'] = $json.Gateways.MtExecConnectors[$i].State
		$Metrics.Coverage.$connectorname['Session'] = @{}
		$ii = 0
		foreach ($session in $json.Gateways.MtExecConnectors[$i].Sessions) {
			$sessionname = $json.Gateways.MtExecConnectors[$i].Sessions[$ii].Name
			$Metrics.Coverage.$connectorname.Session[$sessionname] = @{}
				$Metrics.Coverage.$connectorname.Session.$sessionname['State'] = $json.Gateways.MtExecConnectors[$i].Sessions[$ii].State
			$session=$session
			$ii += 1
			}
	$name=$name
	$i += 1
	}
	
################################___Bridges___################################

$Metrics | Add-Member -MemberType NoteProperty -Name FixBridge -Value @{}
$i = 0
foreach ($name in $json.FixBridges) {
	$n = $i+1
	$bridgename = 'FixBridge'+$n
	$Metrics.FixBridge[$bridgename] = @{}
		$Metrics.FixBridge.$bridgename['Name'] = $json.FixBridges[$i].ServerName
		$Metrics.FixBridge.$bridgename['Client State'] = $json.FixBridges[$i].Client.State
		$Metrics.FixBridge.$bridgename['Plugin State'] = $json.FixBridges[$i].Plugin.State
	$name=$name
	$i += 1
	}
	
################################___MT4Core___################################
#We can be pretty sure that there will be only one MT4Core on the instance, so no need in any loops here

$Metrics | Add-Member -MemberType NoteProperty -Name Mt4Core -Value @{}
$Metrics.Mt4Core['State'] = $json.Core.State
$Metrics.Mt4Core['RMQ'] = @{}
	$Metrics.Mt4Core.RMQ['State'] = $json.Core.RabbitMQConnectionState
	
##################################___LP___##################################

$Metrics | Add-Member -MemberType NoteProperty -Name LP -Value @{}
$i = 0
foreach ($name in $json.Gateways.LPs) {
	$Metrics.LP[$json.Gateways.LPs[$i].Name] = $json.Gateways.LPs[$i].State
	$name=$name
	$i += 1
	}
	
################################___Feeders___###############################

$Metrics | Add-Member -MemberType NoteProperty -Name Feeder -Value @{}
$i = 0
foreach ($name in $json.Gateways.Feeders) {
	$Metrics.Feeder[$json.Gateways.Feeders[$i].Name] = $json.Gateways.Feeders[$i].State
	$name=$name
	$i += 1
	}

#Convert back to the JSON and throw it to the stdout, where Zabbix-agent is already awaiting for the result

$Metrics | ConvertTo-Json -Depth 4
