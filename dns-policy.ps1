<#
.SYNOPSIS
Script to configure Active Directory DNS resolution policies for demonstration
purposes.

.DESCRIPTION
This script configures Active Directory DNS resolution policies for
demonstration purposes. The script creates a DNS zone and then creates "inside"
and "outside" DNS client subnets, zone scopes, and query resolution policies.
The script then creates a DNS record named "test" in each zone scope that points
to a different IP address.

To demonstrate the effect of the DNS resolution policies, query the "test"
record from clients in the "inside" and "outside" subnets and confirm different
answers are returned.

.PARAMETER ZoneName
DNS zone to create or update (for example, "local").

.PARAMETER InsideSubnetCidr
CIDR block for the "inside" DNS client subnet.

.PARAMETER InsideSubnetName
Name for the "inside" DNS client subnet and zone scope.

.PARAMETER OutsideSubnetCidr
CIDR block for the "outside" DNS client subnet.

.PARAMETER OutsideSubnetName
Name for the "outside" DNS client subnet and zone scope.

.INPUTS
None. You cannot pipe input to this script.

.OUTPUTS
None. Writes progress messages to the host.

.EXAMPLE
.\dns-policy.ps1 -ZoneName 'local' -InsideSubnetCidr '10.0.3.0/26' -OutsideSubnetCidr '10.0.3.64/26'

Creates or validates the DNS zone, subnets, zone scopes, test records, and policies using
the provided CIDR ranges.

.LINK
https://github.com/jaredmmartin/active-directory-dns-policy-demo
#>


###### Parameters ######

param(
    [Parameter(Mandatory = $false)]
    [string]$ZoneName = 'local',

    [Parameter(Mandatory = $false)]
    [string]$InsideSubnetCidr = '10.0.3.0/26',

    [Parameter(Mandatory = $false)]
    [string]$InsideSubnetName = 'inside',

    [Parameter(Mandatory = $false)]
    [string]$OutsideSubnetCidr = '10.0.3.64/26',

    [Parameter(Mandatory = $false)]
    [string]$OutsideSubnetName = 'outside'
)

###### Script ######

# Try/catch to create the DNS zone
try {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += ('🏣 Creating ' + $ZoneName + ' zone...')
    Write-Host $Message

    # Get the current zones
    $Zones = Get-DnsServerZone

    # If the zone does not exist, create it
    if ($ZoneName -notin $Zones.ZoneName) {
        # Create the zone
        $Settings = @{
            Name             = $ZoneName
            PassThru         = $true
            ReplicationScope = 'Forest'
        }
        $Zone = Add-DnsServerPrimaryZone @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ Zone present'
        Write-Host $Message
    }
}
catch {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += ('💀 Error: ' + $PsItem)
    Write-Host $Message

    # Throw error
    throw $PsItem
}

# Try/catch to create the inside DNS client subnet, zone scope, and test record
try {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '🌏 [inside] '
    $Message += ('Creating ' + $InsideSubnetName + ' DNS client subnet ')
    $Message += ('for CIDR ' + $InsideSubnetCidr + '...')
    Write-Host $Message

    # Get the subnets
    $Subnets = Get-DnsServerClientSubnet

    # If the default subnet does not exist, create it
    if ($InsideSubnetName -notin $Subnets.Name) {
        # Create the subnet
        $Settings = @{
            IPv4Subnet = $InsideSubnetCidr
            Name       = $InsideSubnetName
            PassThru   = $true
        }
        $SubnetInside = Add-DnsServerClientSubnet @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'DNS client subnet present'
        Write-Host $Message
    }

    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '🌏 [inside] '
    $Message += ('Creating inside zone scope...')
    Write-Host $Message

    # Get the zone scopes
    $Scopes = Get-DnsServerZoneScope -ZoneName $ZoneName

    # If the external zone scope doesn't exist, create it
    if ('inside' -notin $Scopes.ZoneScope) {
        # Create the external zone scope
        $Settings = @{
            Name     = 'inside'
            ZoneName = $ZoneName
        }
        $ScopeInside = Add-DnsServerZoneScope @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'Zone scope present'
        Write-Host $Message
    }

    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '📌 [inside] '
    $Message += ('Creating test.' + $ZoneName + ' record...')
    Write-Host $Message

    # Get the test DNS record in the inside zone scope
    $Settings = @{
        ErrorAction = 'SilentlyContinue'
        Name        = 'test'
        RRType      = 'A'
        ZoneName    = $ZoneName
        ZoneScope   = 'inside'
    }
    $RecordInside = Get-DnsServerResourceRecord @Settings

    # If the inside scope record does not exist, create it
    if (!$RecordInside) {
        # Create the test record
        $Settings = @{
            A           = $true
            IPv4Address = '10.0.0.1'
            Name        = 'test'
            PassThru    = $true
            ZoneName    = $ZoneName
            ZoneScope   = 'inside'
        }
        $RecordInside = Add-DnsServerResourceRecord @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'Record present'
        Write-Host $Message
    }
}
catch {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += ('💀 Error: ' + $PsItem)
    Write-Host $Message

    # Throw error
    throw $PsItem
}

# Try/catch to create the outside DNS client subnet, zone scope, and test record
try {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '🌏 [outside] '
    $Message += ('Creating ' + $OutsideSubnetName + ' DNS client subnet ')
    $Message += ('for CIDR ' + $OutsideSubnetCidr + '...')
    Write-Host $Message

    # Get the subnets
    $Subnets = Get-DnsServerClientSubnet

    # If the default subnet does not exist, create it
    if ($OutsideSubnetName -notin $Subnets.Name) {
        # Create the subnet
        $Settings = @{
            IPv4Subnet = $OutsideSubnetCidr
            Name       = $OutsideSubnetName
            PassThru   = $true
        }
        $SubnetOutside = Add-DnsServerClientSubnet @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'DNS client subnet present'
        Write-Host $Message
    }

    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '🌏 [outside] '
    $Message += ('Creating outside zone scope...')
    Write-Host $Message

    # Get the zone scopes
    $Scopes = Get-DnsServerZoneScope -ZoneName $ZoneName

    # If the external zone scope doesn't exist, create it
    if ('outside' -notin $Scopes.ZoneScope) {
        # Create the external zone scope
        $Settings = @{
            Name     = 'outside'
            ZoneName = $ZoneName
        }
        $ScopeOutside = Add-DnsServerZoneScope @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'Zone scope present'
        Write-Host $Message
    }

    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '📌 [outside] '
    $Message += ('Creating test.' + $ZoneName + ' record...')
    Write-Host $Message

    # Get the test DNS record in the outside zone scope
    $Settings = @{
        ErrorAction = 'SilentlyContinue'
        Name        = 'test'
        RRType      = 'A'
        ZoneName    = $ZoneName
        ZoneScope   = 'outside'
    }
    $RecordOutside = Get-DnsServerResourceRecord @Settings

    # If the outside scope record does not exist, create it
    if (!$RecordOutside) {
        # Create the test record
        $Settings = @{
            A           = $true
            IPv4Address = '10.0.0.255'
            Name        = 'test'
            PassThru    = $true
            ZoneName    = $ZoneName
            ZoneScope   = 'outside'
        }
        $RecordOutside = Add-DnsServerResourceRecord @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'Record present'
        Write-Host $Message
    }
}
catch {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += ('💀 Error: ' + $PsItem)
    Write-Host $Message

    # Throw error
    throw $PsItem
}

# Try/catch to create the inside zone scope resolution policy
try {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '🚔 [inside] '
    $Message += 'Creating resolution policy...'
    Write-Host $Message

    # Get the existing query resolution policies for the zone
    $Policies = Get-DnsServerQueryResolutionPolicy -ZoneName $ZoneName

    # If the inside query resolution policy does not exist, create it
    if ('inside' -notin $Policies.Name) {
        # Create the policy
        $Settings = @{
            Action          = 'ALLOW'
            ClientSubnet    = ('eq,' + $InsideSubnetName)
            Name            = 'inside'
            ProcessingOrder = 1
            ZoneName        = $ZoneName
            ZoneScope       = 'inside,1'
        }
        Add-DnsServerQueryResolutionPolicy @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [inside] '
        $Message += 'Resolution policy exists'
        Write-Host $Message
    }
}
catch {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += ('💀 Error: ' + $PsItem)
    Write-Host $Message

    # Throw error
    throw $PsItem
}

# Try/catch to create the outside zone scope resolution policy
try {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += '🚔 [outside] '
    $Message += 'Creating resolution policy...'
    Write-Host $Message

    # Get the existing query resolution policies for the zone
    $Policies = Get-DnsServerQueryResolutionPolicy -ZoneName $ZoneName

    # If the external query resolution policy does not exist, create it
    if ('outside' -notin $Policies.Name) {
        # Create the policy
        $Settings = @{
            Action          = 'ALLOW'
            ClientSubnet    = ('eq,' + $OutsideSubnetName)
            Name            = 'outside'
            ProcessingOrder = 1
            ZoneName        = $ZoneName
            ZoneScope       = 'outside,1'
        }
        Add-DnsServerQueryResolutionPolicy @Settings

        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'OK'
        Write-Host $Message
    }
    else {
        # Log message
        $Message = ('[' + (Get-Date -Format 'o') + '] ')
        $Message += '✅ [outside] '
        $Message += 'Resolution policy exists'
        Write-Host $Message
    }
}
catch {
    # Log message
    $Message = ('[' + (Get-Date -Format 'o') + '] ')
    $Message += ('💀 Error: ' + $PsItem)
    Write-Host $Message

    # Throw error
    throw $PsItem
}
