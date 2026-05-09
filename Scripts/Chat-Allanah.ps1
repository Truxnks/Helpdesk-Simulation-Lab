$apiKey = ""

$currentTicketFile = "\\CLIENT01\Scripts\current_ticket.txt"
if (Test-Path $currentTicketFile) {
    $currentTicket = Get-Content $currentTicketFile
    $parts = $currentTicket -split " \| "
    $ticketId = $parts[0]
    $currentProblem = $parts[2]
    $currentSymptom = $parts[3]
} else {
    $currentProblem = "unknown issue"
    $currentSymptom = "something is wrong"
}

function Get-AIUserResponse {
    param(
        [string]$actualProblem,
        [string]$technicianQuestion
    )
    
    $personality = "You are Allanah from HR. Your name is Allanah, not Alex or anything else. You understand basic computer terms like internet, wifi, email, and restarting. You DON'T know technical terms like DHCP, DNS, IP or protocols. You are a normal non-technical person in HR but you're not helpless."

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        model = "gpt-4.1-mini"
        messages = @(
            @{
                role = "system"
                content = "$personality The user's computer is having an issue with: '$actualProblem'. But don't repeat what's wrong in every sentence. Just answer the technician's questions naturally, like a real person would. Only mention the problem if asked about it directly."
            },
            @{
                role = "user"
                content = "The technician asked: '$technicianQuestion' Respond as the user in one short sentence. Be natural:"
            }
        )
        max_tokens = 60
        temperature = 1.0
        frequency_penalty = 0.8
        presence_penalty = 0.6
    } | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Uri "" -Method Post -Headers $headers -Body $body -ContentType "application/json"
        return $response.choices[0].message.content.Trim()
    }
    catch {
        $fallbacks = @(
            "I don't know, can you check remotely?",
            "It's still not working right.",
            "I already tried restarting.",
            "Can you help me fix this?",
            "I'm not sure what else to try."
        )
        return $fallbacks | Get-Random
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ALLANAH BROWN (HR DEPARTMENT)" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Current Problem: $currentProblem" -ForegroundColor Yellow
Write-Host "Ticket ID: $ticketId" -ForegroundColor Gray
Write-Host "Computer: CLIENT01 (192.168.1.100)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Commands: 'remote' - RDP to CLIENT01, 'done' - finish, 'exit' - quit" -ForegroundColor Cyan
Write-Host ""

while ($true) {
    $question = Read-Host "[HELPDESK] You"
    
    if ($question -eq "exit") { break }
    if ($question -eq "remote") { 
        Write-Host "Opening RDP to CLIENT01..." -ForegroundColor Yellow
        mstsc /v:192.168.1.100
        continue 
    }
    if ($question -eq "done") { 
        Write-Host "Ticket URL: https://192.168.1.30:8080" -ForegroundColor Cyan
        break 
    }
    
    $response = Get-AIUserResponse -actualProblem $currentProblem -technicianQuestion $question
    Write-Host "[Allanah] $response" -ForegroundColor Green
}
