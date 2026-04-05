# Defense-in-Depth: System Design

The following diagram represents the overall workings of the database system that is able to handle various threats that are stated in the threat model.


- Use proxy server/s (HAProxy | PgBouncer | ProxySQL ) to perfrm security checks and handle DOS attacks.
- Set statement_timeout on db server which aborts any statement that takes more than the specified time.
- Use WAL-G for maintaining Physical Backups and Point-in-Time Recovery (PITR)
- Use Network File System (NFS), a folder that lives on a different server but is mounted so it looks like a local folder on the DB server, to store database logs.
```mermaid
---
config:
  layout: elk
  elk:
    nodePlacementStrategy: LINEAR_SEGMENTS
---
flowchart LR
    subgraph X [X.509]
        subgraph C [Certificate Authoroty - CA]
            CA[CA Certificatre]
            PK[Private Key - PK]
        end
        subgraph I [Intermediate CA]
            ICA[Certificate]
            IPK[Private Key - PK]
        end
        
        CC[Client Certificate]
        SC[Server Certificate]
        C --issues--> ICA
        I --issues--> CC
        I --issues--> SC
        
    end
    subgraph Network
        At[Attacker]

        subgraph Clients [Clients with CA Certificate & Corrosponding PKs]
            A[Client1]
            B[Client2]
        end
        
        subgraph Server [ Servers with CA Certificates & PK]
            App[Web Server]
            Proxy[Proxy Server]
        end

        subgraph DB [PostgreSQL & Recovery Mecanism]
            LKS@{ shape: cyl, label: "LUKS"}
            POS[PostgreSQL]
            WAL[WAL-G]
        end
        Clients --> App
        App --> Proxy
        Proxy --> POS
        POS --> LKS
        POS --> WAL
    end
    subgraph DBB [Backup Servers]
        BKP@{ shape: cyl, label: "DB Clone"}
        LOG[DB Logs]
        WAL[WAL-G]
    end
    WAL --> BKP
    WAL --> LOG    
```