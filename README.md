# CLI-tool - Windows Process Reporter

A simple PowerShell utility to generate detailed reports of running processes on Windows systems.

## Sample Output

The tool generates comprehensive process information including:
- Process ID and Name
- User running the process
- CPU usage (total seconds)
- Memory usage (MB)
- Start time and status
- Priority class and executable path
- Company information

## Data Visualization

This project includes two ways to visualize your process data:

### LibreOffice Calc Charts
- **Guide**: [docs/visualization-guide.odt](docs/Visualization guide.odt)
- Create charts in LibreOffice Calc
- Three chart types: Memory usage bar chart, User distribution donut chart, CPU vs Memory scatter plot

### Interactive HTML Dashboard
- **File**: [docs/dashboard.html](docs/dashboard.html)
- **Features**: Drag & drop file upload, real-time charts, sortable tables
- **Usage**: Open in browser, upload your CSV/JSON file, explore your data

## Installation & Setup

### Option 1: Quick Setup (2 minutes)
```powershell
# Download ZIP from GitHub and extract, then in PowerShell:
cd cli-tool
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\CLI-tool.ps1 -Help
```

### Option 2: Full Setup with Testing (Windows)

#### Prerequisites
- **Windows** (PowerShell 5.1 or later)
- **Optional**: Git for version control

#### Installation Steps

1. **Get the code**:
   - **Option A**: Download ZIP from GitHub and extract
   - **Option B**: If you have Git: `git clone https://github.com/VeeMindless/cli-tool.git`

2. **Set execution policy** (Windows PowerShell):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Test the installation**:
   ```powershell
   cd cli-tool
   .\tests\tests.ps1
   ```

4. **Generate your first report**:
   ```powershell
   .\CLI-tool.ps1 -OutputFormat CSV -OutputFile "my-processes.csv"
   ```

#### Ansible Deployment Setup (Deb 12)

#### Prerequisites
- **Linux** (Deb 12)
- **Required**: Git, Ansible

Deploy to multiple Windows servers automatically:

1. **Install Ansible in and prerequisites in virtualenv**:
   ```bash
   cd /home/<user>
   python3 -m venv ansible
   cd ansible
   bin/pip install ansible pywinrm
   source bin/activate
   ```

2. **Clone the repository**
   ```bash
   cd /home/<user>
   git clone git@github.com:VeeMindless/CLI-tool.git
   ```
3. **Enable and Configure WinRM on you Windows host (HTTP enabled)**
   ***Run powershell as administrator, then run these commands***:
   ***Setup winrm***
   ```bash
   Enable-PSRemoting -Force
   ```
   ***In case you get error "WinRM firewall exception will not work since one of the network
   connection types on this machine is set to Public.", set your interface NetworkCategory to Private or Domain in case you use AD (we will use Private in this case)***:
   ```bash
   Set-NetConnectionProfile -NetworkCategory Private
   ```
   ***Then continue with these commands***:
   
   ```bash
   winrm quickconfig -Force
   winrm set winrm/config/service/auth '@{Basic="true"}'
   winrm set winrm/config/service '@{AllowUnencrypted="true"}'
   winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'
   netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
   ```
   ***Configure User Account***
   ```bash
   net user Administrator /active:yes
   net user Administrator <YourSecurePassword>
   ```
   
4. **Configure Ansible INventory** in `deployment/ansible/hosts.yml` (in case you have a DNS server setup, you can just use the FQDN of the host and omit the ansible_host parameter):

   ***Adjust your ansible_host IP accordingly***
   ```yaml
   [all]
   host1 ansible_host=1.1.1.1

   [all:vars]
   ansible_connection=winrm
   ansible_port=5985
   ansible_user=Administrator
   ansible_password=<YourSecurePassword>
   ansible_winrm_server_cert_validation=ignore
   ```

6. **Deploy** 
   ```bash
   cd deployment/ansible
   ansible-playbook -i hosts.yml cli-tool-deploy.yml
   ```

**What it does**:
- Creates `C:\Tools\CLI-tool` on each server
- Copies all files
- Runs installation tests
- Runs the CLI-tool if tests pass and generates a JSON report
- Downloads the reports into ./reports/$timestamp>/$hostname

#### CI/CD Pipeline Setup

The repository includes GitHub Actions that automatically:
1. **Tests** your code on every commit
2. **Validates** PowerShell syntax
3. **Deploys** to test servers when tests pass (note that ansible hosts.yml file must be edited with correct IPs accordingly)

Pipeline status: [![CI Status](https://github.com/VeeMindless/cli-tool/workflows/Simple%20CI%20for%20CLI-tool/badge.svg)](https://github.com/VeeMindless/cli-tool/actions)

Enable by pushing to GitHub - the pipeline is in `.github/workflows/ci.yml`.

## Testing

Run the built-in test script to verify everything works:

```powershell
.\tests\tests.ps1
```

**What it tests:**
- ✅ Script syntax validation
- ✅ Parameter validation
- ✅ CSV/JSON output generation
- ✅ File format correctness
- ✅ Error handling

## Repository Structure

```
cli-tool/
├── CLI-tool.ps1                 # Main script
├── tests/tests.ps1              # Test script
├── deployment/ansible/          # Ansible deployment
├── docs/                        # Documentation & dashboard
└── .github/workflows/           # CI/CD pipeline
```

## Configuration

The script works out-of-the-box with no configuration required. 

- **Custom Output Paths**: Specify with `-OutputFile` parameter

## Examples

### Basic Usage
```powershell
# Generate today's process report
.\CLI-tool.ps1 -OutputFormat CSV -OutputFile "daily-processes.csv"

# Generate JSON report
.\CLI-tool.ps1 -OutputFormat JSON -OutputFile "processes.json"

# View help
.\\CLI-tool.ps1 -Help
```

### Scheduled Reports
```powershell
# Create scheduled task (run as Administrator)
schtasks /create /tn "Daily Process Report" /tr "powershell.exe -File C:\cli-tool\src\CLI-tool.ps1 -OutputFormat CSV -OutputFile C:\Reports\daily.csv" /sc daily /st 02:00
```

## Troubleshooting

**Common Issues:**

| Problem | Solution |
|---------|----------|
| "Execution Policy" error | Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| "Access Denied" for some processes | Run PowerShell as Administrator |
| Empty User field | Normal for system processes |
| Tests fail | Ensure you're in the repository root directory |
| Ansible fails | Enable WinRM: `Follow the Ansible Deployment Setup guide` |

## Links

- **Documentation**: [docs/](docs/)
- **CI/CD**: [GitHub Actions](https://github.com/VeeMindless/cli-tool/actions)
