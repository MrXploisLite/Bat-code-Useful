@echo off
echo Trying to optimize internet connection...
ipconfig /flushdns
ipconfig /release
ipconfig /renew
netsh int ip reset
netsh winsock reset
ipconfig /registerdns
netsh interface ipv4 reset
netsh interface ipv6 reset
netsh winhttp reset proxy

rem Additional optimizations
netsh interface tcp set global autotuninglevel=normal
netsh interface tcp set global rss=enabled
netsh interface tcp set global chimney=enabled
netsh interface tcp set global ecncapability=disabled
netsh interface tcp set global netdma=enabled
netsh interface tcp set heuristics disabled
netsh interface tcp set global dca=enabled
netsh interface tcp set global timestamps=enabled
netsh interface tcp set global sack=enabled
netsh interface tcp set global autotuning=normal
netsh interface tcp set global congestionprovider=ctcp
netsh interface tcp set global ecncapability=disabled

rem Increase the TCP window size
netsh interface tcp set supplemental template=custom icwnd=65535

rem Disable Nagle's algorithm
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpAckFrequency /t REG_DWORD /d 1 /f

rem Enable Compound TCP (CTCP)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableCompoundTcp /t REG_DWORD /d 1 /f

rem Disable Background Intelligent Transfer Service (BITS)
sc config bits start= disabled

rem Disable Windows Update service
sc config wuauserv start= disabled

echo Internet connection optimized.
