[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$ApiKey = ""
$Uri = ""

$headers = @{
    "Accept" = "application/json"
    "authtoken" = $ApiKey
}

$userName = "allanah.brown"

$problems = @(
    @{ Name = "No Internet - Adapter Disabled"; Create = { Disable-NetAdapter -Name "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue }; Symptom = "No internet, red X on network icon" }
    @{ Name = "DHCP Client Stopped"; Create = { ipconfig /release }; Symptom = "Computer says 'Identifying...' forever" }
    @{ Name = "Windows Time Off"; Create = { Set-Date -Date "2025-01-01" -ErrorAction SilentlyContinue }; Symptom = "Computer clock shows wrong time" }
    @{ Name = "Windows Audio Stopped"; Create = { Stop-Service -Name "Audiosrv" -Force }; Symptom = "No sound from speakers" }
    @{ Name = "Print Spooler Stopped"; Create = { Stop-Service -Name "Spooler" -Force }; Symptom = "Printer not responding" }
    @{ Name = "Network Drive Missing"; Create = { net use I: /delete 2>$null }; Symptom = "The shared drive is gone" }
    @{ Name = "Keyboard Language Changed"; Create = { Set-WinUserLanguageList -LanguageList "fr-FR" -Force }; Symptom = "Typing gives wrong letters" }
    @{ Name = "Desktop Icons Missing"; Create = { 
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDesktop" -Value 1 -Force -Type DWord
        Stop-Process -Name "explorer" -Force
        Start-Sleep -Seconds 2
        Start-Process "explorer.exe"
    }; Symptom = "All my desktop icons and files are gone!" }
    @{ Name = "Website Shows as Not Secure"; Create = { Set-Date -Date "2025-01-01" -ErrorAction SilentlyContinue }; Symptom = "Browser says 'Not Secure' on every website" }
    @{ Name = "Bluetooth Not Working"; Create = { Stop-Service -Name "BTAGService" -Force -ErrorAction SilentlyContinue }; Symptom = "Can't connect to Bluetooth devices" }
    @{ Name = "USB Drive Not Detected"; Create = { $usb = Get-PnpDevice | Where-Object {$_.FriendlyName -like "*USB*" -and $_.Class -ne "Keyboard" -and $_.Class -ne "Mouse"} | Select -First 1; if($usb){ Disable-PnpDevice -InstanceId $usb.InstanceId -Confirm:$false -ErrorAction SilentlyContinue } }; Symptom = "USB drive not showing up" }
    @{ Name = "File Recovery Needed"; Create = {
        $workFolder = "C:\Users\Public\Documents\ImportantFiles"
        if (!(Test-Path $workFolder)) {
            New-Item -Path $workFolder -ItemType Directory -Force
            "Q1 Sales Report: Total $1.2M" | Out-File -FilePath "$workFolder\SalesReport.txt"
            "Employee Contracts - 2025" | Out-File -FilePath "$workFolder\Contracts.txt"
            "Budget Allocation" | Out-File -FilePath "$workFolder\Budget.txt"
        }
        Remove-Item -Path "$workFolder\*" -Force
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    }; Symptom = "Important files were deleted! Need recovery!" }
    @{ Name = "Lost Login Credentials"; Create = {
        for($i=1; $i -le 5; $i++) {
            net user allanah.brown WrongPassword /domain 2>$null
        }
    }; Symptom = "User says: 'I forgot my password and now I'm locked out!'" }
    @{ Name = "Slow Computer Performance"; Create = {
        1..2 | ForEach-Object {
            Start-Job -Name "SlowPC$_" -ScriptBlock { 
                while($true){ 1..10000000 | ForEach-Object { $_ * $_ } }
            }
        }
    }; Symptom = "Computer is extremely slow" }
    @{ Name = "Intermittent Network Drops"; Create = { 
        netsh interface ipv4 set subinterface "Ethernet 2" mtu=500 store=persistent
    }; Symptom = "Internet is very slow and keeps timing out" }
    @{ Name = "DNS Cache Corrupted"; Create = { 
        Clear-DnsClientCache
        Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "8.8.8.8"
    }; Symptom = "Some websites won't load" }
)

$weightedProblems = @()
foreach ($problem in $problems) {
    $weight = 1
    if ($problem.Name -match "No Internet|Lost Login") { $weight = 3 }
    if ($problem.Name -match "File Recovery") { $weight = 2 }
    1..$weight | ForEach-Object { $weightedProblems += $problem }
}
$selectedProblem = $weightedProblems | Get-Random

$priority = if ($selectedProblem.Name -match "No Internet|Lost Login|File Recovery") { "High" } else { "Medium" }


$vagueTitles = @(
    "My internet is not working",
    "Computer is acting weird",
    "Can't get online",
    "Something is wrong with my computer",
    "Need help please",
    "Nothing is loading",
    "Help! Computer problem",
    "It's broken",
    "Can't do my job",
    "Please fix this"
)

$hrDescriptions = @(
    "I can't get to any websites. The internet was working yesterday but today nothing loads. Can you please help?",
    "My computer is being very slow and I can't open any files. I have payroll to run today.",
    "The screen looks different and I can't find my documents. I'm not sure what happened.",
    "I keep getting an error message but I closed it. Now nothing works properly.",
    "The printer isn't working and I need to print these documents for HR. Please help quickly."
)

$randomSubject = $vagueTitles | Get-Random
$randomDescription = $hrDescriptions | Get-Random

$fullDescription = "$randomDescription

---
Technical symptom (for IT): $($selectedProblem.Symptom)
Computer: $env:COMPUTERNAME"

$jsonPayload = @{
    request = @{
        subject = $randomSubject
        description = $fullDescription
        requester = @{ name = $userName }
        priority = @{ name = $priority }
        status = @{ name = "Open" }
    }
} | ConvertTo-Json -Depth 4

$body = @{ input_data = $jsonPayload }

try {
    $response = Invoke-RestMethod -Uri $Uri -Method Post -Body $body -Headers $headers
    Write-Host "TICKET SUBMITTED!" -ForegroundColor Green
    
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $userName | $($selectedProblem.Name) | $env:COMPUTERNAME | Priority: $priority"
    Add-Content -Path "C:\Scripts\ticket_log.csv" -Value $logEntry
    
    $ticketId = $response.request.id
    $currentTicket = "$ticketId | $userName | $($selectedProblem.Name) | $($selectedProblem.Symptom) | Priority: $priority"
    Set-Content -Path "C:\Scripts\current_ticket.txt" -Value $currentTicket
    Write-Host "Current ticket saved to current_ticket.txt" -ForegroundColor Gray
    Write-Host "Ticket ID: $ticketId" -ForegroundColor Gray
    
} catch {
    Write-Host "Ticket failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Check ServiceDesk for ticket." -ForegroundColor Green
