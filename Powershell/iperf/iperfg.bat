copy iperf3.exe \\%1\c$ >NUL
copy cygwin1.dll \\%1\c$ >NUL

copy iperf3.exe \\%2\c$ >NUL
copy cygwin1.dll \\%2\c$ >NUL

psexec -d \\%2 c:\iperf3.exe -s -1
rem psexec \\%1 c:\iperf3.exe -c %2 
psexec \\%1 c:\iperf3.exe -c %2 -t 10 -f g

psexec -d \\%1 c:\iperf3.exe -s -1
rem psexec \\%2 c:\iperf3.exe -c %1 
psexec \\%2 c:\iperf3.exe -c %1 -t 10 -f g

del \\%1\c$\iperf3.exe >NUL
del \\%1\c$\cygwin1.dll >NUL

del \\%2\c$\iperf3.exe >NUL
del \\%2\c$\cygwin1.dll >NUL