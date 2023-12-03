@echo off
echo Trying to optimize internet connection for higher download speed...
netsh interface tcp set global autotuninglevel=normal
netsh interface tcp set global rss=enabled
netsh interface tcp set global chimney=enabled
netsh interface tcp set global ecncapability=disabled
netsh interface tcp set global netdma=enabled
netsh interface tcp set heuristics disabled
netsh interface tcp set global dca=enabled
netsh interface tcp set global timestamps=enabled
netsh interface tcp set global sack=enabled
netsh interface tcp set global autotuning=experimental
netsh interface tcp set global congestionprovider=ctcp
netsh interface tcp set global ecncapability=disabled

rem Adjust TCP window sizes for potentially better performance
netsh interface tcp set supplemental template=custom icwnd=64240
netsh interface tcp set supplemental template=custom rwin=64240

echo Internet connection optimized for higher download speed (up to 80Mbps).
