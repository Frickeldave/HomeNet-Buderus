# KM200 - Documentation

Thanks to <https://github.com/web-km200/web-km200>

## Device name

 It shows up with host name TK-850-JH3E-NET in DHCP Server. When opening <http://TK-850-JH3E-NET/> in a browser, then an empty web page displays. Any URL other than / shows

``` Sorry, the requested file does not exist on this server. ```

This includes URLs that should exist like <http://TK-850-JH3E-NET/gateway/DateTime>.

## Web request

The existing software solutions use a custom user-agent header in the http request, TeleHeater/x.y.z, where x.y.z is a version number. When making a GET request after changing the browser's user agent to TeleHeater (with or without slash version number), the response is different: The web server responds with a "Content-Type: application/json" header, but the body will not contain json data but contain some base64-encoded data, which causes browsers to either show a different error message like "unable to parse json" with a button to show the raw data, or show the raw data directly.

Easier than using the browser with a changed user agent is to retrieve the encoded data with a curl command

```bash
curl -s -A TeleHeater http://$_kmAddress/gateway/DateTime --output $_kmCurlOut
```

The content will be a base64 encoded and **encrypted** string value, which you can easily decode with:

```bash
grep .. $_kmCurlOut | base64 --decode
```

... where `$_kmCurlOut` is your received text from the KM200 unit.

To read the values in cleartext you have to decrypt them.
The decryption key is created from 3 pieces of information:

- The gateway password of the Web KM200 device as printed on a sticker on the outside of that device, without the dashes. 16 charecters.  
*Example: dfljkOIJj389kHu8*  
- The private password previously created in the smartphone app.  
*Example: fdSJakij3sDFj* (It's a good idea not to use sepcial characters)
- A sequence of 32 magic bytes.  
*These: 0x86, 0x78, 0x45, 0xe9, 0x7c, 0x4e, 0x29, 0xdc, 0xe5, 0x22, 0xb9, 0xa7, 0xd3, 0xa3, 0xe0, 0x7b, 0x15, 0x2b, 0xff, 0xad, 0xdd, 0xbe, 0xd7, 0xf5, 0xff, 0xd8, 0x42, 0xe9, 0x89, 0x5a, 0xd1, 0xe4*  

The decryption key is the concatenation of the MD5 sums of

- The concatenation of the gateway password and the magic byte sequence.
- The concatenation of magic byte sequence and the private password.

````bash
_kmPart1=$(echo -n "$_kmStaticGatewayPassword$_kmMagic" | md5sum | cut -c-32)
_kmPart2=$(echo -n "$_kmMagic$_kmUserPassword" | md5sum | cut -c-32)
_kmKey="$_kmPart1$_kmPart2"
````

Now you can use openssl to decrypt the value:

```bash
openssl enc -aes-256-ecb -d -nopad -K $_kmKey
```

## Sources

**AES Key generator**
<https://ssl-account.com/km200.andreashahn.info/>

**Debugging manual**
<https://www.tessera.co.jp/Download/TK-850JH3E+NET_UM_E.pdf>

## API Description from IOBroker

The API is not offical documentated. I collected all the information from several source in web. The endpoints available depends on the system configuration (ie: solar vs no solar, type of regulation,..).

- <https://forum.iobroker.net/assets/uploads/files/1586638349335-km200.pdf>
- <https://forum.logicmachine.net/showthread.php?tid=2057>

| Path                                               | OK  | Example             | Description                                                                                  |
| :------------------------------------------------- | :-- | :------------------ | :------------------------------------------------------------------------------------------- |
| /notifications                                     | -   | null                |                                                                                              |
| **Common gateway information**                     |     |                     |                                                                                              |
| /gateway/boschSHPassword                           | -   |                     |                                                                                              |
| /gateway/firmware                                  | -   |                     |                                                                                              |
| /gateway/haiPassword                               | -   |                     |                                                                                              |
| /gateway/knxPassword                               | -   |                     |                                                                                              |
| /gateway/portalPassword                            | -   |                     |                                                                                              |
| /gateway/update                                    | -   | Exitc. 22           |                                                                                              |
| /gateway/userpassword                              | -   |                     |                                                                                              |
| /gateway/uuid                                      | x   | 123456789           | UUID of the modul                                                                            |
| /gateway/versionFirmware                           | x   | 04.08.02            | Firmwareversion                                                                              |
| /gateway/versionHardware                           | x   | iCom_Low_NSC_v1     | Hardwareversion                                                                              |
| /gateway/DateTime                                  | x   | 2022-02-11T09:17:25 | Date and time of the Moduls                                                                  |
| /gateway/instPassword                              | -   | Exitc. 22           |                                                                                              |
| /gateway/version                                   | -   | Exitc. 22           |                                                                                              |
| /gateway/instAccess                                | x   | off                 |                                                                                              |
| /gateway/instWriteAccess                           | x   | off                 |                                                                                              |
| **Hot water circuits**                             |     |                     |                                                                                              |
| /dhwCircuits/dhw1/actualTemp                       |     | 35.6                |                                                                                              |
| /dhwCircuits/dhw1/charge                           |     |                     |                                                                                              |
| /dhwCircuits/dhw1/chargeDuration                   |     |                     |                                                                                              |
| /dhwCircuits/dhw1/cpStartph                        |     |                     |                                                                                              |
| /dhwCircuits/dhw1/currentSetpoint                  |     |                     |                                                                                              |
| /dhwCircuits/dhw1/operationMode                    | x   | high                |                                                                                              |
| /dhwCircuits/dhw1/singleChargeSetpoint             |     |                     |                                                                                              |
| /dhwCircuits/dhw1/status                           | x   | ACTIVE              |                                                                                              |
| /dhwCircuits/dhw1/switchPrograms                   |     |                     |                                                                                              |
| /dhwCircuits/dhw1/tdMode                           |     |                     |                                                                                              |
| /dhwCircuits/dhw1/tdsetPoint                       |     |                     |                                                                                              |
| /dhwCircuits/dhw1/temperatureLevels                |     |                     |                                                                                              |
| /dhwCircuits/dhw1/temperatureLevels/high           |     |                     |                                                                                              |
| /dhwCircuits/dhw1/temperatureLevels/off            |     |                     |                                                                                              |
| /dhwCircuits/dhw1/waterFlow                        | x   | 0                   |                                                                                              |
| /dhwCircuits/dhw1/workingTime                      | x   | 45335               |                                                                                              |
| **System information**                             |     |                     |                                                                                              |
| /system                                            | -   |                     |                                                                                              |
| /system/info                                       | -   |                     |                                                                                              |
| /system/appliance                                  | -   |                     |                                                                                              |
| /system/brand                                      | x   | Buderus             | Vendor                                                                                       |
| /system/systemType                                 | x   | NSC_ICOM_GATEWAY    | Name of gateways                                                                             |
| /system/bus                                        | x   | EMS2_0              | Bustype in system                                                                            |
| /system/healthStatus                               | x   | ok                  | Overall state of systems                                                                     |
| /system/minOutdoorTemp                             | -   |                     |                                                                                              |
| **Sensor data**                                    | -   |                     |                                                                                              |
| /system/sensors/temperatures                       | -   |                     |                                                                                              |
| /system/sensors/temperatures/outdoor_t1            | x   | 2.3                 | Outside temperature                                                                          |
| /system/sensors/temperatures/supply_t1_setpoint    | x   | 35                  | Temperature threshold for heating system specifued as "boiler set temperature" in the system |
| /system/sensors/temperatures/supply_t1             | x   | 34.8                | Flow temperature                                                                             |
| /system/sensors/temperatures/hotWater_t1           | -   | Exitc. 22           |                                                                                              |
| /system/sensors/temperatures/hotWater_t2           | x   | 37.7                | Hot water temperature at the tapping                                                         |
| /system/sensors/temperatures/return                | -   | -3276.8             | Return flow temperature                                                                      |
| /system/sensors/temperatures/switch                | -   | -3276.8             |                                                                                              |
| /system/sensors/temperatures/chimney               | -   | -3276.8             | Exhaust gas temperature                                                                      |
| /system/appliance/flameCurrent                     | -   | Exitc. 22           |                                                                                              |
| /system/appliance/actualSupplyTemperature          | x   | 40                  | Flow temperature                                                                             |
| /system/appliance/powerSetpoint                    | -   | Exitc. 22           |                                                                                              |
| /system/appliance/actualPower                      | -   | Exitc. 22           | current system power                                                                         |
| /system/appliance/CHpumpModulation                 | -   | Exitc. 22           | Heating pump modulation                                                                      |
| /system/appliance/numberOfStarts                   | -   | Exitc. 22           | Burner starts                                                                                |
| /system/appliance/gasAirPressure                   | -   | Exitc. 22           | applied gas pressure                                                                         |
| /system/appliance/systemPressure                   | -   | Exitc. 22           | Pressure in the heating circuit                                                              |
| /system/appliance/ChimneySweeper                   | -   | Exitc. 22           |                                                                                              |
| /system/appliance/workingTime/totalSystem          | -   | Exitc. 22           | Operating hours counter (total system)                                                       |
| /system/appliance/workingTime/secondBurner         | -   | Exitc. 22           |                                                                                              |
| /system/appliance/workingTime/centralHeating       | -   | Exitc. 22           | Operating hours counter (heating system)                                                     |
| /system/appliance/nominalBurnerLoad                | -   | Exitc. 22           | Nominal burner load                                                                          |
| /system/heatSources                                | -   |                     |                                                                                              |
| /system/heatSources/hs1                            | -   |                     |                                                                                              |
| /system/heatSources/hs1/energyReservoir            | -   | Exitc. 22           |                                                                                              |
| /system/heatSources/hs1/reservoirAlert             | -   | Exitc. 22           |                                                                                              |
| /system/heatSources/hs1/nominalFuelConsumption     | -   | Exitc. 22           |                                                                                              |
| /system/heatSources/hs1/fuelConsmptCorrFactor      | -   | Exitc. 22           |                                                                                              |
| /system/heatSources/hs1/actualModulation           | -   | Exitc. 22           |                                                                                              |
| /system/heatSources/hs1/actualPower                | -   | Exitc. 22           | current performance in HK1                                                                   |
| /system/heatSources/hs1/fuel/density               | -   | Exitc. 22           | Fuel density                                                                                 |
| /system/heatSources/hs1/fuel/caloricValue          | -   | Exitc. 22           |                                                                                              |
| /system/holidayModes                               | -   |                     |                                                                                              |
| /system/holidayModes/hm1                           | -   |                     |                                                                                              |
| /system/holidayModes/hm1/assignedTo                | -   |                     |                                                                                              |
| /system/holidayModes/hm1/delete                    | -   |                     |                                                                                              |
| /system/holidayModes/hm1/dhwMode                   | -   |                     |                                                                                              |
| /system/holidayModes/hm1/hcMode                    | -   |                     |                                                                                              |
| /system/holidayModes/hm1/startStop                 | -   |                     |                                                                                              |
| /system/holidayModes/hm2                           | -   |                     |                                                                                              |
| /system/holidayModes/hm2/assignedTo                | -   |                     |                                                                                              |
| /system/holidayModes/hm2/delete                    | -   |                     |                                                                                              |
| /system/holidayModes/hm2/dhwMode                   | -   |                     |                                                                                              |
| /system/holidayModes/hm2/hcMode                    | -   |                     |                                                                                              |
| /system/holidayModes/hm2/startStop                 | -   |                     |                                                                                              |
| /system/holidayModes/hm3                           | -   |                     |                                                                                              |
| /system/holidayModes/hm3/assignedTo                | -   |                     |                                                                                              |
| /system/holidayModes/hm3/delete                    | -   |                     |                                                                                              |
| /system/holidayModes/hm3/dhwMode                   | -   |                     |                                                                                              |
| /system/holidayModes/hm3/hcMode                    | -   |                     |                                                                                              |
| /system/holidayModes/hm3/startStop                 | -   |                     |                                                                                              |
| /system/holidayModes/hm4                           | -   |                     |                                                                                              |
| /system/holidayModes/hm4/assignedTo                | -   |                     |                                                                                              |
| /system/holidayModes/hm4/delete                    | -   |                     |                                                                                              |
| /system/holidayModes/hm4/dhwMode                   | -   |                     |                                                                                              |
| /system/holidayModes/hm4/hcMode                    | -   |                     |                                                                                              |
| /system/holidayModes/hm4/startStop                 | -   |                     |                                                                                              |
| /system/holidayModes/hm5                           | -   |                     |                                                                                              |
| /system/holidayModes/hm5/assignedTo                | -   |                     |                                                                                              |
| /system/holidayModes/hm5/delete                    | -   |                     |                                                                                              |
| /system/holidayModes/hm5/dhwMode                   | -   |                     |                                                                                              |
| /system/holidayModes/hm5/hcMode                    | -   |                     |                                                                                              |
| /system/holidayModes/hm5/startStop                 | -   |                     |                                                                                              |
| **Recordings**                                     | -   |                     |                                                                                              |
| /recordings/heatingCircuits                        | -   |                     |                                                                                              |
| /recordings/heatingCircuits/hc1                    | -   |                     |                                                                                              |
| /recordings/heatingCircuits/hc1/roomtemperature    | -   |                     |                                                                                              |
| /recordings/heatSources                            | -   |                     |                                                                                              |
| /recordings/heatSources/actualCHPower              | -   |                     |                                                                                              |
| /recordings/heatSources/actualDHWPower             | -   |                     |                                                                                              |
| /recordings/heatSources/actualPower                | -   |                     |                                                                                              |
| /recordings/heatSources/hs1                        | -   |                     |                                                                                              |
| /recordings/heatSources/hs1/actualPower            | -   |                     |                                                                                              |
| /recordings/system                                 | -   |                     |                                                                                              |
| /recordings/system/heatSources                     | -   |                     |                                                                                              |
| /recordings/system/heatSources/hs1                 | -   |                     |                                                                                              |
| /recordings/system/heatSources/hs1/actualPower     | -   |                     |                                                                                              |
| /recordings/system/sensors                         | -   |                     |                                                                                              |
| /recordings/system/sensors/temperatures            | -   |                     |                                                                                              |
| /recordings/system/sensors/temperatures/outdoor_t1 | -   |                     |                                                                                              |
| **heatingCircuits**                                | -   |                     |                                                                                              |
| /heatingCircuits/hc1                               | -   |                     |                                                                                              |
| /heatingCircuits/hc1/controlType                   | -   |                     |                                                                                              |
| /heatingCircuits/hc1/currentOpModeInfo             | -   |                     |                                                                                              |
| /heatingCircuits/hc1/designTemp                    | -   |                     |                                                                                              |
| /heatingCircuits/hc1/heatCurveMax                  | -   |                     |                                                                                              |
| /heatingCircuits/hc1/heatCurveMin                  | -   |                     |                                                                                              |
| /heatingCircuits/hc1/nextSetpoint                  | -   |                     |                                                                                              |
| /heatingCircuits/hc1/roomInfluence                 | -   |                     |                                                                                              |
| /heatingCircuits/hc1/roomTempOffset                | -   |                     |                                                                                              |
| /heatingCircuits/hc1/setpointOptimization          | -   |                     |                                                                                              |
| /heatingCircuits/hc1/solarInfluence                | -   |                     |                                                                                              |
| /heatingCircuits/hc1/suWiSwitchMode                | -   |                     |                                                                                              |
| /heatingCircuits/hc1/suWiThreshold                 | -   |                     |                                                                                              |
| /heatingCircuits/hc1/switchPrograms                | -   |                     |                                                                                              |
| /heatingCircuits/hc1/temperatureLevels             | -   |                     |                                                                                              |
| /heatingCircuits/hc1/timeToNextSetpoint            | -   |                     |                                                                                              |
| /heatingCircuits/hc1/currentRoomSetpoint           | x   | 24                  |                                                                                              |
| /heatingCircuits/hc1/actualSupplyTemperature       | x   | 30.3                | Flow temperature for HK1                                                                     |
| /heatingCircuits/hc1/operationMode                 | x   | auto                | Operating mode (auto/man)                                                                    |
| /heatingCircuits/hc1/temperatureRoomSetpoint       | -   | Exitc. 22           |                                                                                              |
| /heatingCircuits/hc1/manualRoomSetpoint            | -   |                     |                                                                                              |
| /heatingCircuits/hc1/temporaryRoomSetpoint         | -   | -1                  |                                                                                              |
| /heatingCircuits/hc1/roomtemperature               | -   | -3276.8             | Room temperature in reference room for HK1                                                   |
| /heatingCircuits/hc1/activeSwitchProgram           | x   | A                   | Active heating program (A or B) for HK1                                                      |
| /heatingCircuits/hc1/switchPrograms/A              | -   | null                | Daten für Programm A                                                                         |
| /heatingCircuits/hc1/switchPrograms/B              | -   | null                | Daten für Programm B                                                                         |
| /heatingCircuits/hc1/temperatureLevels/eco         | x   | 20                  | Solltemperatur im Absenkbetrieb                                                              |
| /heatingCircuits/hc1/temperatureLevels/comfort2    | x   | 24                  | Solltemperatur für Heizbetrieb                                                               |
| /heatingCircuits/hc1/temperatureLevels/day         | -   | Exitc. 22           | Solltemperatur für Heizbetrieb                                                               |
| /heatingCircuits/hc1/temperatureLevels/night       | -   | Exitc. 22           | Solltemperatur für Absenkbetrieb                                                             |
| /heatingCircuits/hc1/pumpModulation                | x   | 68                  | Modulation der Heizpumpe für HK1                                                             |
| /heatingCircuits/hc1/fastHeatupFactor              | x   | 0                   |                                                                                              |
| /heatingCircuits/hc1/status                        | x   | ACTIVE              | Betriebsanzeige HK1                                                                          |
| **Solar circuits**                                 | -   |                     |                                                                                              |
| /solarCircuits/sc1/collectorTemperature            | -   |                     |                                                                                              |
| /solarCircuits/sc1/pumpModulation                  | -   |                     |                                                                                              |
| /solarCircuits/sc1/solarYield                      | -   |                     |                                                                                              |
| /solarCircuits/sc1/status                          | -   |                     |                                                                                              |
| /solarCircuits/sc1/dhwTankTemperature              | x   | 25.8                | Warmwassertemperatur im Speicher (unten) für SC1                                             |
| /solarCircuits/sc1/solarYield                      | x   | 0                   | Solarertrag im SC1                                                                           |
| /solarCircuits/sc1/pumpModulation                  | x   | 0                   | Modulation der Solarpumpe im SC1                                                             |
| /solarCircuits/sc1/collectorTemperature            | x   | 10.5                | Kollektortemperatur im SC1                                                                   |
| /solarCircuits/sc1/actuatorStatus                  | x   | yes                 |                                                                                              |
| /solarCircuits/sc1/status                          | x   | ACTIVE              | Betriebsanzeige SC1                                                                          |
| **Heat sources**                                   | -   |                     |                                                                                              |
| /heatSources/actualModulation                      | -   |                     |                                                                                              |
| /heatSources/applianceSupplyTemperature            | -   |                     |                                                                                              |
| /heatSources/burnerModulationSetpoint              | -   |                     |                                                                                              |
| /heatSources/burnerPowerSetpoint                   | -   |                     |                                                                                              |
| /heatSources/flameCurrent                          | -   |                     |                                                                                              |
| heatSources/energyMonitoring/consumption           | x   | 781.4               | Total consumption                                                                            |
| heatSources/energyMonitoring/startDateTime         | x   | 2022-02-07T20:37:27 | Start of consumption measurement                                                             |
| /heatSources/hs1                                   | -   |                     |                                                                                              |
| /heatSources/hs1/actualCHPower                     | -   |                     |                                                                                              |
| /heatSources/hs1/actualDHWPower                    | -   |                     |                                                                                              |
| /heatSources/hs1/CHpumpModulation                  | -   |                     |                                                                                              |
| /heatSources/hs1/flameStatus                       | -   |                     |                                                                                              |
| /heatSources/hs1/fuel                              | -   |                     |                                                                                              |
| /heatSources/hs1/fuel/caloricValue                 | -   |                     |                                                                                              |
| /heatSources/hs1/fuel/density                      | -   |                     |                                                                                              |
| /heatSources/hs1/fuelConsmptCorrFactor             | -   |                     |                                                                                              |
| /heatSources/hs1/info                              | -   |                     |                                                                                              |
| /heatSources/hs1/nominalCHPower                    | -   |                     |                                                                                              |
| /heatSources/hs1/nominalDHWPower                   | -   |                     |                                                                                              |
| /heatSources/hs1/nominalFuelConsumption            | -   |                     |                                                                                              |
| /heatSources/hs1/numberOfStarts                    | -   |                     |                                                                                              |
| /heatSources/hs1/reservoirAlert                    | -   |                     |                                                                                              |
| /heatSources/hs1/supplyTemperatureSetpoint         | -   |                     |                                                                                              |
| /heatSources/hs1/type                              | -   | GasBoiler           | Type of header                                                                               |
| /heatSources/info                                  | -   |                     |                                                                                              |
| /heatSources/nominalCHPower                        | -   |                     |                                                                                              |
| /heatSources/nominalDHWPower                       | -   |                     |                                                                                              |
| /heatSources/numberOfStarts                        | -   |                     |                                                                                              |
| /heatSources/powerSetpoint                         | -   |                     |                                                                                              |
| /heatSources/returnTemperature                     | -   |                     |                                                                                              |
| /heatSources/supplyTemperatureSetpoint             | -   |                     |                                                                                              |
| /heatSources/systemPressure                        | -   |                     |                                                                                              |
| /heatSources/workingTime                           | -   |                     |                                                                                              |
| /heatSources/workingTime/centralHeating            | -   |                     |                                                                                              |
| /heatSources/workingTime/secondBurner              | -   |                     |                                                                                              |
| /heatSources/workingTime/totalSystem               | -   |                     |                                                                                              |
| /heatSources/actualPower                           | x   | 5.2                 | aktuelle Brennerleistung                                                                     |
| /heatSources/actualCHPower                         | x   | 5.2                 | aktuelle genutzte Leistung des Heizsystems                                                   |
| /heatSources/actualDHWPower                        | x   | 0                   | aktuell genutzte Leistung des Warmwassersystems                                              |
| /heatSources/flameStatus                           | x   | on                  | Brennerstatus (Flamme oder nicht)                                                            |
| /heatSources/CHpumpModulation                      | x   | 72                  | Modulation der Heizpumpe                                                                     |
| /heatSources/actualsupplytemperature               | -   | Exitc. 22           | Vorlauftemperatur                                                                            |
| /heatSources/powerSetpoint                         | x   | 100                 |                                                                                              |
| /heatSources/gasAirPressure                        | x   | 0                   | anliegender Gasdruck                                                                         |
| /heatSources/systemPressure                        | x   | 25.5                | Druck im Heizsystem                                                                          |
| /heatSources/ChimneySweeper                        | x   | off                 |                                                                                              |
| /heatSources/powerSetpoint                         | x   | 100                 |                                                                                              |
| /heatSources/returnTemperature                     | -   | -3276.8             | Rücklauftemperatur                                                                           |
| /heatSources/numberOfStarts                        | x   | 48224               | Anzahl der Brennerstarts                                                                     |
| /heatSources/nominalCHPower                        | x   | 14                  | Nominale Leistung des Heizsystems                                                            |
| /heatSources/nominalDHWPower                       | x   | 15                  | Nominale Leistung des Warmwassersystems                                                      |
| /heatSources/workingTime/totalSystem               | x   | 876491              | Betriebsstunden (Gesamtsystem)                                                               |
| /heatSources/workingTime/secondBurner              | x   | 0                   |                                                                                              |
| /heatSources/workingTime/centralHeating            | x   | 831156              | Betriebsstunden (Heizsystem)                                                                 |
