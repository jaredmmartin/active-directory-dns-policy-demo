# active-directory-dns-policy-demo

PowerShell script to setup a demo of Active Directory DNS resolution policies

## Overview

This script configures Active Directory DNS resolution policies for
demonstration purposes. The script creates a DNS zone and then creates "inside"
and "outside" DNS client subnets, zone scopes, and query resolution policies.
The script then creates a DNS record named "test" in each zone scope that points
to a different IP address.

```mermaid
---
config:
    flowchart:
        curve: 'monotoneX'
        nodeSpacing: 20
        inheritDir: true
        defaultRenderer: "elk"
    themeVariables:
        fontFamily: 'monospace'
        fontSize: '12px'
        lineColor: '#ededed'
        edgeLabelBackground: 'transparent'
---
flowchart LR
    subgraph network ["network"]
        subgraph dns_server ["dns server"]
            subgraph dns_zone [".local (zone)"]
                %% Nodes
                dns_record_test@{ shape: flag, label: "test.local (record)"}

                %% Node styles
                dns_record_test:::dns_record
            end
        end

        subgraph inside ["10.0.3.0/26 (inside)"]
            %% Nodes
            dns_client_inside@{ shape: st-rect, label: "client(s)"}

            %% Node styles
            dns_client_inside:::dns_client
        end

        %% child.lab.test domain
        subgraph outside ["10.0.3.64/26 (outside)"]
            %% Nodes
            dns_client_outside@{ shape: st-rect, label: "client(s)"}

            %% Node styles
            dns_client_outside:::dns_client
        end

        %% Chart styles
        dns_server:::dns_server
        dns_zone:::subgroup
        inside:::subgroup
        outside:::subgroup

        %% Node links
        dns_client_inside e1@--query test.local--> dns_server
        dns_server e2@--answer 10.0.0.1--> dns_client_inside
        dns_client_outside e3@--query test.local--> dns_server
        dns_server e4@--answer 10.0.0.255--> dns_client_outside
    end

    %% Chart styles
    network:::network

    %% Link styles
    class e1 animate_fast
    class e2 animate_fast
    class e3 animate_fast
    class e4 animate_fast

    %% Style classes
    classDef animate_fast stroke-dasharray: 7,1,stroke-dashoffset: 500,animation: dash 45s linear infinite
    classDef animate_slow stroke-dasharray: 7,1,stroke-dashoffset: 500,animation: dash 60s linear infinite
    classDef dns_client fill:#e6be22,stroke:#212529,stroke-width:1px,color:#212529
    classDef dns_record fill:#37b24d,stroke:#37b24d,stroke-width:1px,color:#fff
    classDef dns_server fill:#4c6ef5,stroke:#4c6ef5,stroke-width:1px,color:#fff
    classDef network fill:#212529,stroke:#212529,stroke-width:1px,color:#fff
    classDef subgroup fill:#343a40,stroke:#343a40,stroke-width:1px,color:#fff
```

To demonstrate the effect of the DNS resolution policies, query the "test"
record from clients in the "inside" and "outside" subnets and confirm different
answers are returned.

## Requirements

+ Active Directory domain with DNS
+ DNS clients in inside and outside subnets

## Usage

```pwsh
.\dns-policy.ps1 -ZoneName 'local' -InsideSubnetCidr '10.0.3.0/26' -OutsideSubnetCidr '10.0.3.64/26'
```

## Useful documentation

[DNS Policies Overview](https://learn.microsoft.com/en-us/windows-server/networking/dns/deploy/dns-policies-overview)
