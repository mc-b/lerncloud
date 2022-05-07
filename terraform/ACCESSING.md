Zugriff auf den Server
======================

User / Password
---------------

* Der User ist ubuntu, dass Password steht in der cloud-init.yaml Datei.

Einloggen mittels

    ssh ubuntu@${ip}

    
SSH
---

Auf der Server kann mittels ssh zugegriffen werden.

Der private SSH Key ist hier: https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud. 

Downloaden und dann wie folgt auf den Server einloggen:

* ssh -i lerncloud ubuntu@${ip}

Hinweis: Windows User verwenden bitvise und legen den privaten SSH Key im "Client key manager" ab.