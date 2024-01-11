#Import PFX certificate to local certificate store .
#Import module Web Administration
Import-Module WebAdministration

#Location to store the certificate.
$certStore = 'Cert:\LocalMachine\My'

#Friendly Name of the certificate.
$certFrindlyName = 'FriendlyName of certificate

#Subject Name of the certificate
$cerSubject = 'CN=domain.com'

#Location where certificate is stored.
#$certPath = "C:\Path\To\Certificate.pfx"

#Get old certificate from local certificate store.
$certRemove = Get-ChildItem $certStore | where{$_.Subject -eq $cerSubject}

#Save password as secure string.
$PWD = ConvertTo-SecureString "password" -AsPlainText -Force

#Get Thumbprint of old certificate.
$OldCertThumbprint = $certRemove.Thumbprint

Write-Host "Old Certificate Thumbprint: $OldCertThumbprint"

#Check if certificate is exist in local certificate store. FriendlyName must defined to certificate.
If ($certRemove.FriendlyName -eq $certFrindlyName)
{
    #Retrive all sites and thumbprint which are bind in IIS.
    $siteThumbs = Get-ChildItem IIS:SSLBindings | Foreach-Object {

        $thumb = $_.Thumbprint

        foreach ($site in $_.Sites.Value) {
            [PSCustomObject]@{
             Site       = $site
             Thumbprint = $thumb
             }
          
          #Match old certificate thumbprint with assigned sites   
          If($thumb -eq $OldCertThumbprint)
          {
                Write-Host $site "Thumbprint" $thumb

                $certRemove | Remove-Item #Remove the old certificate from store.

                $ImportCert = Import-PfxCertificate -FilePath $certPath -CertStoreLocation $certStore -Password $PWD -Exportable #Import new certificate.

                $cert = Get-ChildItem $certStore | where{$_.Subject -eq $cerSubject}

                $cert.FriendlyName = $certFrindlyName #Assign Friendly Name to new certificate.

                $binding = Get-WebBinding -Name $site -Protocol "https" #Get site name.
                
                $binding.AddSslCertificate($ImportCert.GetCertHashString(), "my") #Bind new certificate to site.

                Write-Host "Certificate is sucessful bind to: $site"

          }
          Else
          {
            Write-Host "No match certificate thumbprint found in certificate store."
          }
        }
    }
}
Else
{
    Write-Host "Importing certificate first time...You have to bind the certificate to site/sites manually after import..."

    $ImportCert = Import-PfxCertificate -FilePath $certPath -CertStoreLocation $certStore -Password $PWD -Exportable

    $cert = Get-ChildItem $certStore | where{$_.Subject -eq $cerSubject}

    $cert.FriendlyName = $certFrindlyName
}
