function Initialize-KM200Api {
    [CmdletBinding()]
	<#
    .SYNOPSIS
	    Starts the REST API
    .DESCRIPTION
	    Get heating information from the Buderus KM200 module
	.PARAMETER Port
		The port of the Rest API
    .EXAMPLE
	    Initialize-KM200Api -Port 9876
    .NOTES
    .LINK
	    https://github.com/Frickeldave/HomeNet-Buderus
    #>

	param (
		[Parameter(Mandatory=$false)]
		[ValidateRange(1024,65535)]
		[string]$Port=8081
	)

	$script:Verbose = $false
	if ($PSBoundParameters.ContainsKey('Verbose')) {
		$script:Verbose = $PsBoundParameters.Get_Item('Verbose')
		Write-Verbose "Verbose mode is active"
	}

	try {

		Write-Host "Initialize API"

		Import-Module -Name Pode -Verbose:$($script:Verbose) #TODO: Change to a nested module in module definition, currently not working when specifying in required modules 

		Start-PodeServer {

			Add-PodeEndpoint -Address * -Port $Port -Protocol Http

			New-PodeLoggingMethod -Custom -ArgumentList $_loggingOptions -ScriptBlock {
				param ( $item, $options )
				Write-Host "$($item.message)"
			} | Add-PodeLogger -Name "log" -ScriptBlock {
				param ($item, $logOpts) # BUG: "logOpts" is just a dummy parameter. When you remove that, it will not work anymore.
				$logOpts | Out-Null
				return $item
			}

			Write-Host "Initialize route ""getall"""
			Add-PodeRoute -Method Get -Path '/api/smarthome/km200/getall' -ScriptBlock {

				function Get-KM200Value {
					[CmdletBinding()]
					param (
						[string]$KMPath
					)

					Write-PodeLog -Name "log" -InputObject @{message="Send request to KM200 api ""$KMPath"""}
					$_kmReturnValue = & "$PSScriptRoot/buderus-km200.sh" "$KMPath" "1"
					return $_kmReturnValue
				}

				try {
					$_kmGetAllStartMs=(Get-Date).Millisecond
					Write-PodeLog -Name "log" -InputObject @{message="Prepare powershell object"}
					$_kmGetAllHeatingObj = New-Object -Type psobject
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "DeviceId" -Value $(Get-KM200Value -KMPath "gateway/uuid")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "Firmware" -Value $(Get-KM200Value -KMPath "gateway/versionFirmware")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "Health" -Value $(Get-KM200Value -KMPath "system/healthStatus")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "OutdoorTempC" -Value $(Get-KM200Value -KMPath "system/sensors/temperatures/outdoor_t1")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "FlowTempC" -Value $(Get-KM200Value -KMPath "system/sensors/temperatures/supply_t1")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "OperationMode" -Value $(Get-KM200Value -KMPath "heatingCircuits/hc1/operationMode")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "CollectorTemperatur" -Value $(Get-KM200Value -KMPath "solarCircuits/sc1/collectorTemperature")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "NumberOfStarts" -Value $(Get-KM200Value -KMPath "heatSources/numberOfStarts")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "FlameStatus" -Value $(Get-KM200Value -KMPath "heatSources/flameStatus")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "TotalSystemUptimeMin" -Value $(Get-KM200Value -KMPath "heatSources/workingTime/totalSystem")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "TotalConsumption" -Value $(Get-KM200Value -KMPath "heatSources/energyMonitoring/consumption")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "TotalConsumptionMeasureStart" -Value $(Get-KM200Value -KMPath "heatSources/energyMonitoring/startDateTime")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "ElapsedTimeMs" -Value $(Get-KM200Value -KMPath "")
					$_kmGetAllHeatingObj | Add-Member -MemberType NoteProperty -Name "CurrentTime" -Value (Get-Date -Format "yyyy-MM-dd HH:mm K")

					

					$_kmGetAllEndMs=(Get-Date).Millisecond
					$_kmGetAllElapsedTimeMs = ($($_kmGetAllEndMs - $_kmGetAllStartMs)).ToString()
					$_kmGetAllHeatingObj.ElapsedTimeMs = $_kmGetAllElapsedTimeMs
					Write-PodeJsonResponse -Value ($_kmGetAllHeatingObj | ConvertTo-Json)
					Write-PodeLog -Name "log" -InputObject @{message="Request finished. Elapsed time (ms): $_kmGetAllElapsedTimeMs"}

				} catch {
					$Response.Send("Failed to get heating information.")
				}
			}
		}

		$_kmInitElapsedTimeMs = $($_kmGetAllEndMs - $_kmGetAllStartMs)
		Write-Host "API initalized (took $_kmInitElapsedTimeMs ms)"

	}
	catch {
		Exit 1
	}
}