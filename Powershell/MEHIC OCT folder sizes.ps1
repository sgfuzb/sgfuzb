Invoke-Command -ComputerName MEHIC6 -ScriptBlock {((Get-ChildItem "E:\Topcon\OCT\Data" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHIC6 -ScriptBlock {((Get-ChildItem "E:\Topcon\OCT\Archive" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHIC6 -ScriptBlock {((Get-ChildItem "E:\Topcon\OCT\Reports" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}

Invoke-Command -ComputerName MEHIC9 -ScriptBlock {((Get-ChildItem "E:\Topcon\OCT\Data" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHIC9 -ScriptBlock {((Get-ChildItem "E:\Topcon\OCT\Archive" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHIC9 -ScriptBlock {((Get-ChildItem "E:\Topcon\OCT\Reports" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}

Invoke-Command -ComputerName MEHICEAL -ScriptBlock {((Get-ChildItem "e:\Imaging\OCT 2000 50K\DATA" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICEAL -ScriptBlock {((Get-ChildItem "e:\Imaging\OCT 2000 50K\Archive" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICEAL -ScriptBlock {((Get-ChildItem "e:\Imaging\OCT 2000 50K\Reports" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}

Invoke-Command -ComputerName MEHICME -ScriptBlock {((Get-ChildItem "e:\Topcon\Data" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICME -ScriptBlock {((Get-ChildItem "e:\Topcon\Archive" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICME -ScriptBlock {((Get-ChildItem "e:\Topcon\Reports" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}

Invoke-Command -ComputerName MEHICNWP -ScriptBlock {((Get-ChildItem "e:\Imaging\OCT 2000 50K\Data" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICNWP -ScriptBlock {((Get-ChildItem "e:\Imaging\OCT 2000 50K\Archive" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICNWP -ScriptBlock {((Get-ChildItem "e:\Imaging\OCT 2000 50K\Reports" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}

Invoke-Command -ComputerName MEHICSTA -ScriptBlock {((Get-ChildItem "e:\OCT\Data" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICSTA -ScriptBlock {((Get-ChildItem "e:\OCT\Archive" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICSTA -ScriptBlock {((Get-ChildItem "e:\OCT\Reports" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}

Invoke-Command -ComputerName MEHICSG -ScriptBlock {((Get-ChildItem "q:\OCT 2000 50K\Data" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICSG -ScriptBlock {((Get-ChildItem "q:\OCT 2000 50K\Archive" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}
Invoke-Command -ComputerName MEHICSG -ScriptBlock {((Get-ChildItem "q:\OCT 2000 50K\Reports" -Recurse | Measure-Object -Property Length -Sum).Sum)/1GB}

