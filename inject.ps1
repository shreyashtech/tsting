Start-Sleep -Seconds 15

# 🔗 Replace this with your DLL's RAW GitHub URL
$dllUrl = "https://raw.githubusercontent.com/shreyashtech/tsting/main/chams.dll"

# Download DLL into memory
$webClient = New-Object System.Net.WebClient
$dllBytes = $webClient.DownloadData($dllUrl)

# Save temp DLL (required for LoadLibraryA - memory-only alternative is complex)
$tempPath = "$env:TEMP\temp_inject.dll"
[IO.File]::WriteAllBytes($tempPath, $dllBytes)

# Get HD-Player process
$proc = Get-Process -Name "HD-Player" -ErrorAction SilentlyContinue
if ($proc) {
    $pid = $proc.Id

    $code = @"
using System;
using System.Runtime.InteropServices;
public class Inject {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
    [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
    [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string lpModuleName);
    public static void InjectDLL(int pid, string dllPath) {
        IntPtr hProcess = OpenProcess(0x1F0FFF, false, pid);
        IntPtr addr = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)((dllPath.Length + 1) * 2), 0x1000 | 0x2000, 0x40);
        byte[] bytes = System.Text.Encoding.Unicode.GetBytes(dllPath);
        UIntPtr outSize;
        WriteProcessMemory(hProcess, addr, bytes, (uint)bytes.Length, out outSize);
        IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryW");
        CreateRemoteThread(hProcess, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
    }
}
"@

    Add-Type $code
    [Inject]::InjectDLL($pid, $tempPath)

    Start-Sleep -Seconds 3
    Remove-Item $tempPath -Force
}
