$printers | Export-Clixml c:\test.xml
$printers.Clear()
$printers = Import-Clixml c:\test.xml
$printers.Count

