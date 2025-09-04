# LolbinsInjectDLL

LolbinsInjectDLL

This project is a proof‑of‑concept script that uses built‑in Windows programs (so‑called "lolbins") to inject a DLL into another process. The batch file Lolscript.bat takes a DLL file and uses waitfor.exe and mavinject.exe to load it into a process.

How it works

The script checks if it is running with Administrator privileges and makes sure that waitfor.exe and mavinject.exe are available.

It starts waitfor.exe with a random signal name. This creates a dummy process.

It finds the process ID (PID) of the dummy process using tasklist.

It uses mavinject.exe to inject the chosen DLL into that process.

Finally, it signals waitfor.exe to exit.

Usage
Lolscript.bat <full_path_to_dll> [timeout_seconds] [signal_name]


full_path_to_dll – the full path to the DLL you want to inject.

timeout_seconds – optional: how long to wait before trying to inject (default is 5 seconds).

signal_name – optional: the signal name used with waitfor.exe (a random name is used if you omit this).

Example:

Lolscript.bat C:\Path\To\MyDll.dll

Requirements

Windows 10 or later.

Administrator rights.

The files mavinject.exe and waitfor.exe must be present (they come with Windows).

Warning

DLL injection is a technique used in security research and can be detected by security products. Use this script only in a lab environment or on systems you own and have permission to test.
