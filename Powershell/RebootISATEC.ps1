$Servers = "MEHISATEC"

foreach ($Server in $Servers)
{
	"Computer $Server initiated reboot at $(Get-Date)"
	Restart-Computer $Server -Force
    ping -n 50 $server
}