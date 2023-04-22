copy iperf3.exe \\%1\c$ >NUL
copy cygwin1.dll \\%1\c$ >NUL

copy iperf3.exe \\%2\c$ >NUL
copy cygwin1.dll \\%2\c$ >NUL

psexec -d \\%2 c:\iperf3.exe -s -1
rem psexec \\%1 c:\iperf3.exe -c %2 
rem psexec \\%1 c:\iperf3.exe -c %2 -t 10 -i 10 -w 600K -P 5
psexec \\%1 c:\iperf3.exe -c %2 -t 10 -i 10 -w 600K

psexec -d \\%1 c:\iperf3.exe -s -1
rem psexec \\%2 c:\iperf3.exe -c %1 
rem psexec \\%2 c:\iperf3.exe -c %1 -t 10 -i 10 -w 600K -P 5
psexec \\%2 c:\iperf3.exe -c %1 -t 10 -i 10 -w 600K

