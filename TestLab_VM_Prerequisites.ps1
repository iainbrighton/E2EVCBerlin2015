#requires -RunAsAdministrator

<#
    Cannot push to virtual machine as the firewall is enabled by default. This should
    be invoked by TestLabVMPrerequisites.bat to initially bypass the restricted
    execution policy.
#>

# Set local machine execution policy to Remote Signed
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell -Name ExecutionPolicy -Value Unrestricted;

## Get the Hyper-V hostname
$hypervHost = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters' -ErrorAction Stop | Select-Object -ExpandProperty Hostname;

## Import certificates for DSC credential signing from Test Lab Host "Resource" share
$certificatePath = "\\$hypervHost\Resources";
$rootCACertificate = Get-ChildItem -Path 'Cert:\LocalMachine\Root' | Where-Object Subject -eq 'CN=Test Lab Root Authority, OU=Test Lab, O=Virtual Engine, C=UK';
if (-not $rootCACertificate) {
    Write-Host "Importing Root CA Certificate";
    $rootCACertificatePath = Join-Path -Path $certificatePath -ChildPath 'TestLabRootCA.cer';
    $rootCACertificate = Import-Certificate -FilePath $rootCACertificatePath -CertStoreLocation 'Cert:\LocalMachine\Root';
}
$dscClientCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object Subject -eq 'CN=Test Lab DSC Client';
if (-not $dscClientCertificate) {
    Write-Host "Importing DSC Client Certificate";
    $certificatePassword = ConvertTo-SecureString -String 'T3stlab' -Force -AsPlainText;
    $dscClientCertificatePath = Join-Path -Path $certificatePath -ChildPath 'TestLabDSCClient.pfx';
    $dscClientCertificate = Import-PfxCertificate -FilePath $dscClientCertificatePath -CertStoreLocation 'Cert:\LocalMachine\My' -Password $certificatePassword;
}

## Import all DSC resources
Copy-Item -Path "\\$hypervHost\Resources\DSCResources\*" -Destination "$env:ProgramFiles\WindowsPowershell\Modules" -Recurse -Force;

## Disable Server Manager
Write-Host "Disabling Server Manager Autostart";
[ref] $null = Disable-ScheduledTask -TaskPath ‘\Microsoft\Windows\Server Manager\’ -TaskName ‘ServerManager’;
