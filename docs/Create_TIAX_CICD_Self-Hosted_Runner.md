# Setting Up a GitHub Self-Hosted Runner for TIAX test and release on Windows VM

## Prerequisites
- A Windows Virtual Machine (Windows Server 2016 or later recommended)
- Administrative access to your GitHub repository or organization
- PowerShell with administrator privileges
- SIOS account credentials for TIA Portal download
- AX license

## Steps

### 1. Prepare Your Windows VM
1. Ensure your VM meets the minimum requirements:
   - Windows Server 2016 or later / Windows 10 64-bit
   - PowerShell 5.0 or later
   - At least 2GB RAM and 10GB storage

3. Set execution policy to eneble remote script execution: 
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

4. Set Sleep settings to never:
- In Settings -> Power&Sleep set Screen and Sleep settings to Never to avoid VM hibernation


### 2. Install Required Siemens Software

1. Install TIA Portal :
   - Download the desired TIA Portal version installation files from [SIOS](https://support.industry.siemens.com)
   - Follow the installation wizard and complete the installation process

3. Install APAX and the required dependencies:   
   - Install a current [Node.js LTS version](https://nodejs.org/en)
   - Download and install [.NET 8](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)   
   - Download [Visual Studio Build Tools](https://aka.ms/vs/16/release/vs_buildtools.exe) and install using the following command: 

   ```powershell
   .\vs_buildtools.exe --wait --norestart --nocache --passive --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK --add Microsoft.VisualStudio.Component.Windows10SDK.18362
   ```
   
   - Download the NPM Apax package and the required dependencies from [SIMATIC AX Downloads page](https://console.simatic-ax.siemens.io/downloads) and extract the contents into a folder
   - Run the npm install command in the previously created folder: 

   ```powershell
   # Install npm APAX package
   npm install --global apax.tgz
   ```
   
### 3. Configure GitHub Runner

1. Configure token permisions to allow publishing packages:
   - Go to your repository (or organization) settings
   - Click "Actions" in the left sidebar
   - Select "General"
   - In workflow permissions select "Read repository contents and packages permissions"

2. Navigate to GitHub repository settings:
   - Go to your repository (or organization) settings
   - Click "Actions" in the left sidebar
   - Select "Runners"
   - Click "New self-hosted runner"

3. Select Windows as your operating system and architecture (x64)

4. Create a directory for the runner:
```powershell
mkdir C:\actions-runner
cd C:\actions-runner
```

5. Download the runner package:
```powershell
# Replace {DOWNLOAD_URL} with the URL from GitHub
Invoke-WebRequest -Uri "{DOWNLOAD_URL}" -OutFile "actions-runner-win-x64.zip"
```

6. Extract the installer:
```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD\actions-runner-win-x64.zip", "$PWD")
```



### 4. Configure and Start the Runner

1. Run the configuration script:
```powershell
.\config.cmd --url {REPOSITORY_URL} --token {TOKEN}
```
Replace {REPOSITORY_URL} and {TOKEN} with values from GitHub

2. Configure runner options when prompted:
   - Enter a name for your runner (or press Enter for default)
   - Add labels if needed (e.g., 'windows', 'vm', 'tia-portal')
   - Choose work folder location (or press Enter for default)

3. Install and start the runner as a service:
```powershell
.\run.cmd
```

### 5. Verify Installation

1. Check runner status in GitHub:
   - Return to Actions > Runners in GitHub
   - Your new runner should appear as "Idle"

### 6. Maintenance and Security

1. Regular updates:
```powershell
# Stop the runner service
.\run.cmd stop

# Update the runner
.\config.cmd --url {REPOSITORY_URL} --token {TOKEN}

# Restart the service
.\run.cmd
```

2. Security considerations:
   - Keep the VM updated with latest security patches
   - Use strong network security rules
   - Regularly rotate access tokens
   - Monitor runner logs for suspicious activity
   - Keep TIA Portal and AX updated with latest patches

### Troubleshooting

Common issues and solutions:

1. Runner service fails to start:
```powershell
# Check service status
Get-Service "actions.runner.*"

# Review logs
Get-Content "_diag\Runner_*.log"
```

2. Network connectivity issues:
   - Verify outbound access to GitHub
   - Check proxy settings if applicable
   - Ensure firewall rules allow GitHub connections

3. Permission problems:
   - Run PowerShell as Administrator
   - Verify service account permissions
   - Check workspace directory permissions

4. TIA Portal/AX issues:
   - Verify license activation status
   - Check TIA Portal installation logs
   - Ensure all required components are installed

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-hosted Runners Security Guidelines](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#security-considerations)
- [Runner Troubleshooting Guide](https://docs.github.com/en/actions/hosting-your-own-runners/troubleshooting-self-hosted-runners)
- [Siemens Industry Online Support (SIOS)](https://support.industry.siemens.com)
- [SIMATIC AX](https://console.simatic-ax.siemens.io/)
