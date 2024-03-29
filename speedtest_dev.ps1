$CarbonServer = "<INSERT GRAPHITE SERVER HERE";
$CarbonPort = "2003";

$PingDestination = "4.2.2.2";

$TenMBFileURL="http://client.akamai.com/install/test-objects/10MB.bin"


try {
    Test-Connection -ComputerName $PingDestination -Count 2 -ErrorAction Stop | Out-Null
    $PingSuccess = $true;
} catch { # either ping failed or access denied 
    $PingSuccess = $false;
}


if ($PingSuccess) {
    try {
        $Request=Get-Date; Invoke-WebRequest $TenMBFileURL -TimeoutSec 30 | Out-Null;
        [decimal]$speed = ((10 / ((NEW-TIMESPAN –Start $Request –End (Get-Date)).totalseconds)) * 8) 
        "{0:N2}" -f $Speed
    }
    catch {
        $speed = 0.0;
    }

}
else {
    $speed = 0.0;
}



Write-host "$($speed) Mbit/sec"

$time = Get-Date -format "o";

#$table = import-csv -path .\speed_history.csv
$Combined_Info = New-Object -TypeName psobject
$Combined_Info | Add-Member -MemberType NoteProperty -Name Date -Value $time
$Combined_Info | Add-Member -MemberType NoteProperty -Name Result -Value $speed
$Combined_Info | Export-Csv -path .\speed_history.csv -Append

$metric_path = "homelab.$($env:COMPUTERNAME).internet_speed.downloaded";
$value = $speed;
$timestamp = [int](Get-Date -UFormat "%s");

#$timestamp = -1; --use to let carbon determine time

$CarbonString = ($metric_path + " " + $value + " " + $timestamp);

echo $CarbonString

$socket = New-Object System.Net.Sockets.TCPClient;
$socket.Connect($CarbonServer, $CarbonPort);
$stream = $socket.GetStream()
$writer = New-Object System.IO.StreamWriter($stream);
$writer.WriteLine($CarbonString);
$writer.Flush();
$writer.Close();
$stream.close();