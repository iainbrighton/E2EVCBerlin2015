#requires -version 4

configuration DemoConfiguration {

    param (
        [System.String[]] $ComputerName
    )

    node $ComputerName {

        File Reports {
            DestinationPath = 'C:\Reports';
            Ensure = 'Present';
            Type = 'Directory';
        }

        Service WindowsUpdate {
            Name = 'wuauserv';
            StartupType = 'Automatic';
            State = 'Running';
        }

        WindowsFeature RemoteDesktopServices {
            Name = 'RDS-RD-Server';
            Ensure = 'Present';
            DependsOn = '[Service]WindowsUpdate';
        }
    
    } #end node

} #end configuration
