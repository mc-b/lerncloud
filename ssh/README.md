Unsicheres Schlüsselpaar
------------------------

Diese Schlüssel sind "unsichere" öffentliche/private Schlüssel, die beim allen Cloud-init Scripten in [Modules](../modules/) automatisch eingetragen werden.

Damit ist sichergestellt, dass man immer mittels SSH in die VMs gelangen kann.

Wenn Sie mit einem Team oder Unternehmen oder mit einer benutzerdefinierten VM arbeiten und sichereres SSH wünschen, sollten Sie Ihr eigenes Schlüsselpaar erstellen und die Cloud-init Scripte entsprechend anpassen.