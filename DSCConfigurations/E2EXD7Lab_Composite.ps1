configuration E2EXenDesktop76 {
    param (
        ## Installation Active Directory account
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential] $Credential,
        ## Storefront .Pfx certificate password
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential] $PfxCertificateCredential
    )

    Import-DscResource -ModuleName CitrixXenDesktop7Lab;

    ## Need delegated access to all Controllers (NetBIOS and FQDN) and the database server
    $credSSPDelegatedComputers = $ConfigurationData.AllNodes | Where Role -eq 'Controller' | ForEach {
        Write-Output $_.NodeName
        if ($_.NodeName.Contains('.')) { ## Output NetBIOS name as well
            Write-Output ('{0}' -f $_.NodeName.Split('.')[0]);
        }
        else { ## Output FQDN as well
            Write-Output ('{0}.{1}' -f $_.NodeName, $ConfigurationData.NonNodeData.XenDesktop.Site.DomainName);
        }
    };
    $credSSPDelegatedComputers += $ConfigurationData.NonNodeData.XenDesktop.Site.DatabaseServer;
    $siteController = ($ConfigurationData.AllNodes | Where Role -eq 'Controller' | Select -First 1).NodeName;
    $allSiteControllers = ($ConfigurationData.AllNodes | Where Role -eq 'Controller').NodeName;
    $licenseServer = ($ConfigurationData.AllNodes | Where Role -eq 'Licensing' | Select -First 1).NodeName;

#region Licensing

    node $AllNodes.Where{ $_.Role -eq 'Licensing' }.NodeName {
        XD7LabLicenseServer LicenseServer {
            CitrixLicensePath = $ConfigurationData.NonNodeData.XenDesktop.Licensing.LicenseFilePath;
            Credential = $Credential;
            InstallRDSLicensingRole = $true;
            XenDesktopMediaPath = $Node.MediaPath;
        }
    }

#endregion Licensing

#region XenDesktop Controllers
    
    node ($AllNodes | Where Role -eq 'Controller' | Select -First 1).NodeName {
        XD7LabSite FirstSiteController {
            Credential = $Credential;
            DatabaseServer = $ConfigurationData.NonNodeData.XenDesktop.Site.DatabaseServer;
            DelegatedComputers = $credSSPDelegatedComputers;
            LicenseServer = ($ConfigurationData.AllNodes | Where Role -eq 'Licensing' | Select -First 1).NodeName;
            SiteAdministrators = $ConfigurationData.NonNodeData.XenDesktop.Site.Administrators;
            SiteName = $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            XenDesktopMediaPath = $Node.MediaPath;
        }
        
        foreach ($machineCatalog in $ConfigurationData.NonNodeData.XenDesktop.MachineCatalogs) {
            XD7LabMachineCatalog "Catalog_$($machineCatalog.Name.Replace(' ','_'))" {
                Name = $machineCatalog.Name;
                Description = $machineCatalog.Description;
                ComputerName = $ConfigurationData.AllNodes | Where MachineCatalog -eq $machineCatalog.Name | % { $_.NodeName };
                Credential = $Credential;
                DependsOn = '[XD7LabSite]FirstSiteController';
            }
        }

        foreach ($deliveryGroup in $ConfigurationData.NonNodeData.XenDesktop.DeliveryGroups) {
            XD7LabDeliveryGroup "Group_$($deliveryGroup.Name.Replace(' ','_'))" {
                Name = $deliveryGroup.Name;
                DisplayName = $deliveryGroup.DisplayName;
                Description = $deliveryGroup.Description;
                ComputerName = $ConfigurationData.AllNodes | Where DeliveryGroup -eq $deliveryGroup.Name | % { $_.NodeName };
                Users = $deliveryGroup.Users;
                Credential = $Credential;
                DependsOn = '[XD7LabSite]FirstSiteController';
            }
        }
    }
     
    node ($AllNodes | Where Role -eq 'Controller' | Select -Skip 1 | ForEach { $_.NodeName } ) {
        XD7LabController AdditionalSiteController {
            Credential = $Credential;
            DelegatedComputers = $credSSPDelegatedComputers;
            ExistingControllerAddress = ($ConfigurationData.AllNodes | Where Role -eq 'Controller' | Select -First 1).NodeName;
            SiteName = $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            XenDesktopMediaPath = $Node.MediaPath;
        }
    }

#endregion XenDesktop Controllers

#region StoreFront/Director

    node $AllNodes.Where{ $_.Role -eq 'Storefront' }.NodeName {
        XD7LabStorefrontHttps StorefrontHttps {
            ControllerAddress = ($ConfigurationData.AllNodes | Where Role -eq 'Controller' | Select -First 1).NodeName;
            PfxCertificatePath = $ConfigurationData.NonNodeData.XenDesktop.Storefront.PfxCertificatePath;
            PfxCertificateThumbprint = $ConfigurationData.NonNodeData.XenDesktop.Storefront.PfxCertificateThumbprint;
            PfxCertificateCredential = $PfxCertificateCredential;
            XenDesktopMediaPath = $Node.MediaPath;
        }
    }

#endregion StoreFront/Director

#region SessionHostVDA

    node $AllNodes.Where{ $_.Role -eq 'SessionVDA' }.NodeName {
        XD7LabSessionHost SessionHost {
            ControllerAddress = $allSiteControllers;
            RDSLicenseServer = $licenseServer;
            XenDesktopMediaPath = $Node.MediaPath;
        }
    }

#endregion SessionHostVDA

} #end configuration
