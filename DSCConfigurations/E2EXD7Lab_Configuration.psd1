@{
    AllNodes = @(
        @{
            NodeName = '*';                                                                 ## Settings apply to all nodes, but can be overridden by the individual node
            CertificateFile = "\\TESTLABHOST\Resources\Certificates\TestLabDSCClient.cer";  ## Credential encryption certificate public key
            Thumbprint = '34841902EF4BC17250AC4131C365F3A6810E340D';                        ## Credential encryption certificate thumbprint
            MediaPath = "\\TESTLABHOST\Resources\Media\CitrixXenDesktop76";                 ## Node-accessible Citrix XenDesktop 7.6 installation media path
        }
        @{ NodeName = 'EUDBLS01'; Role = 'Licensing'; }
        @{ NodeName = 'E2ESF01'; Role = 'Storefront','Director'; }                          ## Composite resource installs Director on all Storefront servers
        @{ NodeName = 'E2EXC01'; Role = 'Controller','Studio'; }                            ## Composite resource installs Studio on all Controller servers
        @{ NodeName = 'E2EXC02'; Role = 'Controller','Studio'; }
        @{ NodeName = 'E2ESH01'; Role = 'SessionVDA'; MachineCatalog = 'Manual Server Catalog'; DeliveryGroup = 'Server Desktop'; }
        @{ NodeName = 'E2ESH02'; Role = 'SessionVDA'; MachineCatalog = 'Manual Server Catalog'; DeliveryGroup = 'Server Desktop'; }
    )
    NonNodeData = @{
        XenDesktop = @{
            Site = @{
                Name = 'E2EDemo';
                DomainName = 'testlab.local';
                DatabaseServer = 'E2EDB01.testlab.local';
                Administrators = 'XenDesktop Admins','Domain Admins';
            }
            MachineCatalogs = @(
                @{
                    Name = 'Manual Server Catalog';
                    Description = 'Manual RDS Session Hosts';
                }
            )
            DeliveryGroups = @(
                @{
                    Name = 'Server Desktop';
                    DisplayName = 'Standard Desktop';
                    Description = 'Published XenApp Desktop';
                    Users = 'TESTLAB\XenDesktop Users';
                }
            )
            Licensing = @{
                LicenseFilePath = "\\TESTLABHOST\Resources\EUDBLS01_XenDesktop_PLAT_PartnerUse_15022016.lic";
            }
            Storefront = @{
                PfxCertificatePath = '\\TESTLABHOST\Resources\Certificates\star.testlab.local.pfx';
                PfxCertificateThumbprint = 'A4D8B8E3B1B6910CB54C3B6CDFD6478914327850';
            }
        } #end XenDesktop
    } #end nonNodeData
}
