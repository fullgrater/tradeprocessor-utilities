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

#Put all Names in the simple-enough hash-table that we will use for discovering new monitoring items

$discovery = @()
foreach ($name in $json.Gateways.Mt4Connectors.Name) {
	$discovery += @{ '{#MT4_CONNECTOR}' = $name }
	}
foreach ($name in $json.Gateways.Mt5Connectors.Name) {
	$discovery += @{ '{#MT5_CONNECTOR}' = $name }
	}
foreach ($name in $json.Gateways.FixConnectors.Name) {
	$discovery += @{ '{#FIX_CONNECTOR}' = $name }
	}
foreach ($name in $json.Gateways.MtExecConnectors.Name) {
	$discovery += @{ '{#COVERAGE}' = $name }
	}
foreach ($name in $json.Gateways.LPs.Name) {
	$discovery += @{ '{#LP_EXECUTION}' = $name }
	}
foreach ($name in $json.Gateways.Feeders.Name) {
	$discovery += @{ '{#LP_FEEDER}' = $name }
	}
foreach ($name in $json.FixBridges.ServerName) {
	$discovery += @{ '{#FIX_BRIDGE}' = $name }
	}

#Add some kind of header to our list and send it to the stdout
#N.B. Simplicity of the list and "data" header is extremly important for the proper work of discovery in Zabbix

$data = @{ 'data' = $discovery }
$data | ConvertTo-Json
