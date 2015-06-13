$scriptBlock = {

    . 'C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1';
    $storefrontParams = @{
        HostBaseUrl = 'https://storefront.testlab.local';
        FarmName = 'E2EDemo';
        Port = 80;
        TransportType = 'HTTP';
        SslRelayPort = 443;
        Servers = 'e2exc01.testlab.local','e2exc02.testlab.local';
        LoadBalance = $true;
        FarmType = 'XenDesktop';
        StoreFriendlyName ='E2EDemo';
    }
    Set-DSInitialConfiguration @storefrontParams;
}

Invoke-Command -ComputerName e2esf01 -ScriptBlock $scriptBlock;
