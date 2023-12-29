# Import PFX Certificate in certificate store.

# Convert password in SecureString
$PWD = ConvertTo-SecureString "your certificate password" -AsPlainText -Force
$FilePath = "C:\Path\Certificatename.PFX" # Location of PFX certificate file.
$FirendlyName = "Friendly Name of Certificate" # Name to identify the certificate in Certificate store.
$CertificateStore = 'Cert:\LocalMachine\My' # Certificate store location to save the certificate.

$Cert = Import-PfxCertificate -FilePath $FilePath -CertStoreLocation $CertificateStore -Password $PWD -Exportable

# $Cert = Get-ChildItem Cert:\LocalMachine\My | where{$_.Subject -eq "CN=domainname.com"} # To find the certificate using subject name in store.

$Cert.FriendlyName = $FirendlyName
