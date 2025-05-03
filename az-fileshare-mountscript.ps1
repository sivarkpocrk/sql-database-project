$connectTestResult = Test-NetConnection -ComputerName demostoragesi.file.core.windows.net -Port 445

if ($connectTestResult.TcpTestSucceeded) {
    # Save credentials securely to persist drive on reboot
    cmd.exe /C "cmdkey /add:`"demostoragesi.file.core.windows.net`" /user:`"Azure\demostoragesi`" /pass:{$variable}"

    # Mount the Azure file share to drive M:
    New-PSDrive -Name M -PSProvider FileSystem -Root "\\demostoragesi.file.core.windows.net\test1" -Persist
} else {
    Write-Error -Message "Unable to reach Azure File Share over port 445. It may be blocked by your ISP or firewall. Consider using Azure VPN options (P2S, S2S, or ExpressRoute)."
}
