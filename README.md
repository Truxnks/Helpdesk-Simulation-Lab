# Helpdesk Simulation Lab
### Active Directory Homelab with AI-Powered Automation and ManageEngine ServiceDesk Plus

> A fully automated enterprise IT homelab simulating a real corporate environment. Built a 5-VM network from scratch using PowerShell — including domain promotion, DHCP/DNS configuration, OU structure, user provisioning, and Group Policy. Deployed ManageEngine ServiceDesk Plus on-prem with LDAP/AD integration and REST API connectivity. Built a PowerShell automation system that randomly generates and applies real IT issues, submits tickets automatically via API, and uses GPT-4.1-mini to simulate an AI-powered end user for live helpdesk practice. Implemented AppLocker, account lockout policies, drive mapping GPOs, and Control Panel restrictions.

---

## Purpose

Demonstrate hands-on experience with technologies used daily in helpdesk, desktop support, junior sysadmin, and IT security roles — built entirely from scratch using PowerShell, not GUI wizards.

---

## Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────┐
│              corp.local — 192.168.1.0/24                │
└─────────────────────────────────────────────────────────┘
          │
┌─────────┬──────────┬──────────┬──────────┐
│         │          │          │          │
▼         ▼          ▼          ▼          ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│    DC01      │ │   CLIENT01   │ │   CLIENT02   │ │   CLIENT03   │ │   ITSM01     │
│192.168.1.10  │ │192.168.1.100 │ │192.168.1.101 │ │192.168.1.103 │ │192.168.1.30  │
│──────────────│ │──────────────│ │──────────────│ │──────────────│ │──────────────│
│ AD Domain    │ │  Windows 11  │ │ Windows 11   │ │ Windows 11   │ │ ServiceDesk  │
│ DNS Server   │ │ allanah.brown│ │ bryan.hanes  │ │ terry.ryder  │ │ Plus         │
│ DHCP Server  │ │ HR OU        │ │ IT OU        │ │ Sales OU     │ │ LDAP/AD Int. │
│ PDC Emulator │ │ Domain-Joined│ │ Domain-Joined│ │ Domain-Joined│ │ REST API     │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

| VM | Role | IP | OS |
|---|---|---|---|
| DC01 | Primary Domain Controller, DNS, DHCP, PDC Emulator | 192.168.1.10 | Windows Server 2022 |
| CLIENT01 | Domain-joined workstation (allanah.brown / HR) | 192.168.1.100 | Windows 11 Pro |
| CLIENT02 | Domain-joined workstation (terry.ryder / Sales) | 192.168.1.101 | Windows 11 Pro |
| CLIENT03 | Domain-joined workstation (bryan.hanes / IT) | 192.168.1.102 | Windows 11 Pro |
| ITSM01 | ManageEngine ServiceDesk Plus on-prem | 192.168.1.30 | Windows Server 2022 |

---

## Completed Build

### Domain Controller (DC01) — Built via PowerShell

- [x] Windows Server 2022 installed
- [x] Static IP configured via `New-NetIPAddress`
- [x] AD DS forest promoted via `Install-ADDSForest -DomainName "corp.local"`
- [x] DNS server configured and resolving `corp.local`
- [x] DHCP server installed via `Install-WindowsFeature DHCP`
- [x] DHCP scope: 192.168.1.100–200, DNS=192.168.1.10, Gateway=192.168.1.1

### Active Directory Structure — Built via PowerShell

- [x] OU hierarchy: CORP → Departments → IT / HR / Sales → Users / Computers / Groups
- [x] All OUs created via `New-ADOrganizationalUnit`
- [x] Users created via `New-ADUser`:
  - `allanah.brown` — HR Department
  - `terry.ryder` — Sales Department
  - `bryan.hanes` — IT Department
- [x] Users imported into ManageEngine ServiceDesk Plus as requesters

### Client Machines

- [x] CLIENT01 — Windows 11 Pro, domain-joined to `corp.local`, user: allanah.brown (HR)
- [x] CLIENT02 — Windows 11 Pro, domain-joined to `corp.local`, user: terry.ryder (Sales)
- [x] CLIENT03 — Windows 11 Pro, domain-joined to `corp.local`, user: bryan.hanes (IT)
- [x] Static IP configuration on CLIENT01 for Kerberos authentication
- [x] Windows 11 OOBE bypass performed for lab deployment
- [x] All clients verified via `whoami` (`corp\allanah.brown`, `corp\terry.ryder`, `corp\bryan.hanes`)

### Group Policy Objects (7 GPOs Deployed and Verified)

| GPO | Scope | Status |
|---|---|---|
| Account Lockout Policy | Domain | ✅ Active — 5 attempts, 30 min lockout, verified end-to-end |
| Map IT Drive | HR OU | ✅ Active — `\\DC01\IT_Share` mapped as I: |
| Restrict Control Panel | CORP OU | ✅ Active — verified blocked on client |
| AppLocker | Default Domain Policy | ✅ Active — Executable, Installer, Script rules enforced |
| Login Message | Domain | ✅ Active |
| Install Notepad++ | Domain | ✅ Active |
| Set Corporate Homepage | Domain | ✅ Active |

**AppLocker Detail:**
- Executable rules: Enforce
- Windows Installer rules: Enforce
- Script rules: Enforce
- Verified: `msedge.exe` blocked on client with "This app has been blocked by your system administrator"

**Account Lockout Detail:**
- Threshold: 5 invalid logon attempts
- Duration: 30 minutes
- Reset counter after: 30 minutes
- Tested: Account locked out and verified at login screen
- Remediation tested two ways: GUI (ADUC unlock checkbox) and PowerShell (`Unlock-ADAccount`)

### NTFS and Share Permissions

- [x] `\\DC01\IT_Share` created and shared
- [x] NTFS permissions configured: SYSTEM, CORP\Administrators, CORP\Users
- [x] Drive mapping confirmed via `net use` on CLIENT01 (I: → `\\DC01\IT_Share`)
- [x] GPO Preferences used to map drive on login

### ServiceDesk Plus (ITSM01)

- [x] ManageEngine ServiceDesk Plus installed on dedicated VM
- [x] LDAP authentication configured pointing to `ldap://192.168.1.10:389`
- [x] Base DN: `DC=corp,DC=local`
- [x] AD users imported as requesters (allanah.brown, terry.ryder, bryan.hanes)
- [x] Technician accounts configured
- [x] REST API verified — ticket creation via PowerShell confirmed with JSON response
- [x] Live dashboard showing inbound/completed ticket tracking and SLA monitoring
- [x] 40+ tickets logged across simulation sessions

---

## Automation System

This is the core of the project — a fully automated helpdesk training simulator that keeps the lab active without manual intervention.

### How It Works

```
┌─────────────────────────────────────────┐
│  Run-Random.ps1 (Scheduled Task)        │
│  Fires every 15-20 minutes randomly     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Client1-script.ps1                     │
│  Randomly selects 1 of 15 IT issues     │
│  Applies it to CLIENT01                 │
│  Submits vague ticket via REST API      │
│  Logs incident to CSV                   │
│  Saves current ticket to .txt           │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Chat-Allanah.ps1                       │
│  Reads current ticket                   │
│  Loads ticket context into GPT-4.1-mini │
│  Simulates Allanah Brown (HR user)      │
│  Technician chats via PowerShell        │
│  'remote' command opens RDP to CLIENT01 │
└─────────────────────────────────────────┘
```

### IT Issues Simulated (15 Scenarios)

| Issue | Priority | Method |
|---|---|---|
| No Internet — Adapter Disabled | High | `Disable-NetAdapter` |
| DHCP Client Stopped | Medium | `ipconfig /release` |
| Windows Audio Stopped | Medium | `Stop-Service Audiosrv` |
| Print Spooler Stopped | Medium | `Stop-Service Spooler` |
| Network Drive Missing | Medium | `net use I: /delete` |
| Desktop Icons Missing | Medium | Registry + Explorer restart |
| Keyboard Language Changed | Medium | `Set-WinUserLanguageList fr-FR` |
| Website Shows as Not Secure | Medium | System clock manipulation |
| Bluetooth Not Working | Medium | `Stop-Service BTAGService` |
| USB Drive Not Detected | Medium | `Disable-PnpDevice` |
| Windows Time Off | Medium | `Set-Date` |
| File Recovery Needed | High | Creates and deletes files, clears recycle bin |
| Lost Login Credentials | High | Triggers account lockout via bad password loop |
| Slow Computer Performance | Medium | CPU stress via background jobs |
| Intermittent Network Drops | Medium | MTU manipulation via netsh |

**Weighted probability** — High priority issues (No Internet, Lost Login, File Recovery) appear 2-3x more frequently, matching real helpdesk volume distribution.

### Ticket Submission (REST API)

- Tickets submitted to ServiceDesk Plus via REST API using `Invoke-RestMethod`
- Subject lines generated as vague user descriptions ("Help! Computer problem", "Nothing is loading")
- Description includes HR-style language plus technical symptom for IT reference
- Priority assigned automatically based on issue type
- Ticket ID returned in JSON response and saved locally

### AI End User Simulation (GPT-4.1-mini)

- `Chat-Allanah.ps1` loads current ticket context
- GPT-4.1-mini plays Allanah Brown from HR
- Personality: understands "internet" and "restarting" but not DHCP or DNS
- Responds naturally to technician questions in one sentence
- Fallback responses if API unavailable
- `remote` command in chat opens RDP directly to CLIENT01
- `done` command provides ServiceDesk Plus URL to close ticket

---

## Security Implementations

### AppLocker
- Configured via Group Policy Management Editor
- Executable, Windows Installer, and Script rules set to Enforce
- Default allow rules for Program Files and Windows directories
- Custom deny rule: `%PROGRAMFILES%\Microsoft\Edge\Application\msedge.exe`
- Verified end-to-end: browser blocked on domain client with system administrator message

### Account Lockout
- Policy: 5 failed attempts triggers lockout
- Duration: 30 minutes
- Automated trigger: Client1-script.ps1 simulates bad password loop via `net user` commands
- Remediation Method 1: ADUC — Account tab → Unlock account checkbox
- Remediation Method 2: PowerShell — `Unlock-ADAccount -Identity "allanah.brown"`
- Verification: `Get-ADUser -Identity "allanah.brown" -Properties LockedOut` confirms `False`

### Registry-Based Windows 11 Installation Bypass
- TPM, Secure Boot, and RAM checks bypassed via registry keys in `HKLM:\SYSTEM\Setup\Labconfig`
- Keys: `BypassTPMCheck`, `BypassSecureBootCheck`, `BypassRAMCheck` set to `1`

---

## Technologies Used

| Technology | Purpose |
|---|---|
| PowerShell | Entire infrastructure built via command line |
| Windows Server 2022 | Domain Controller (x2), ITSM server |
| Windows 11 Pro | Domain-joined client workstations |
| Active Directory | Domain, OU structure, user management, authentication |
| Group Policy | 7 GPOs including AppLocker and drive mapping |
| ManageEngine ServiceDesk Plus | On-prem ITSM with LDAP/AD integration |
| REST API | Automated ticket creation via PowerShell |
| GPT-4.1-mini (OpenAI) | AI-powered end user simulation |
| VirtualBox | 5-VM virtualization platform |
| Kerberos | Domain authentication via static IP configuration |
| LDAP | ServiceDesk Plus to Active Directory authentication |
| GPG/Encryption | File security in automation scripts |

---

## Scripts

| Script | Description |
|---|---|
| `Scripts/Client1-script.ps1` | Randomly selects and applies 1 of 15 IT issues, submits ticket via REST API |
| `Scripts/Run-Random.ps1` | Self-rescheduling scheduled task, fires every 15-20 minutes |
| `Scripts/Chat-Allanah.ps1` | AI end user simulation via GPT-4.1-mini |

---

## Key Concepts Demonstrated

- Domain promotion and forest creation from command line
- Multi-DC environment with replication
- OU-scoped Group Policy design and enforcement
- AppLocker application whitelisting
- Account lockout policy — configuration, testing, and remediation
- NTFS permissions and network share configuration
- LDAP integration between ticketing system and Active Directory
- REST API consumption from PowerShell
- Weighted random problem generation
- Scheduled task automation with self-rescheduling
- AI API integration for realistic simulation
- OS deployment techniques (OOBE bypass, registry modification)
- Dual-method troubleshooting documentation (GUI and CLI)

---

## Problems Solved During Build

| Problem | Root Cause | Solution |
|---|---|---|
| Domain promotion failed | DSRM password requirement not met | Added `-SafeModeAdministratorPassword` parameter |
| DHCP authorization failed | Domain controller limitation | Registry bypass method |
| Client couldn't join domain | DNS pointing to wrong server | Set DNS to 192.168.1.10 on client |
| AppLocker not enforcing | Application Identity service not running | Enabled and set to Automatic startup |
| ServiceDesk LDAP auth failed | Wrong base DN format | Corrected to `DC=corp,DC=local` |
| Windows 11 TPM requirement | VirtualBox lacks TPM 2.0 | Labconfig registry bypass |
| Ticket API returning 401 | Auth token format incorrect | Corrected header to `authtoken` format |
| Account lockout not triggering | Lockout threshold not set in GPO | Created dedicated Account Lockout Policy GPO |

---

## Repository Structure

```
Helpdesk-Simulation-Lab/
├── README.md
├── homelab/
│   ├── Client1-script.ps1       # Problem generator + ticket submission
│   ├── Run-Random.ps1           # Self-rescheduling scheduled task
│   └── Chat-Allanah.ps1         # AI end user simulation
├── docs/
│   ├── setup-guide.md
│   ├── troubleshooting.md
│   └── tickets.md
└── screenshots/
    ├── dc01/                    # Domain controller setup
    ├── clients/                 # Domain-joined workstations
    ├── gpo/                     # Group Policy configuration and verification
    ├── servicedesk/             # ServiceDesk Plus dashboard and LDAP config
    └── automation/              # Scripts running and ticket output
```

---

## How to Replicate This Lab

### Prerequisites
- VirtualBox installed
- Windows Server 2022 ISO (180-day eval from Microsoft)
- Windows 11 Pro ISO
- 16GB+ RAM on host machine
- 100GB+ free disk space

### Core Build Commands (PowerShell as Administrator on DC01)

```powershell
# Static IP
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "192.168.1.10" -PrefixLength 24 -DefaultGateway "192.168.1.1"
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "127.0.0.1","192.168.1.10"

# Install and promote AD
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "corp.local" -DomainNetbiosName "CORP" -InstallDns -Force

# Install DHCP
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerv4Scope -Name "Corp Network" -StartRange 192.168.1.100 -EndRange 192.168.1.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -DnsServer 192.168.1.10 -Router 192.168.1.1

# Create OU structure
New-ADOrganizationalUnit -Name "CORP" -Path "DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Departments" -Path "OU=CORP,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "HR" -Path "OU=Departments,OU=CORP,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "IT" -Path "OU=Departments,OU=CORP,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Sales" -Path "OU=Departments,OU=CORP,DC=corp,DC=local"

# Create users
New-ADUser -Name "Allanah Brown" -SamAccountName "allanah.brown" -UserPrincipalName "allanah.brown@corp.local" -Path "OU=Users,OU=HR,OU=Departments,OU=CORP,DC=corp,DC=local" -AccountPassword $SecurePassword -Enabled $true
New-ADUser -Name "Terry Ryder" -SamAccountName "terry.ryder" -UserPrincipalName "terry.ryder@corp.local" -Path "OU=Users,OU=Sales,OU=Departments,OU=CORP,DC=corp,DC=local" -AccountPassword $SecurePassword -Enabled $true
```

---

*Built by Giovanni Moore — CompTIA A+ | Network+ | Security+*  
*LinkedIn: linkedin.com/in/giovanni-moore-408589362*
