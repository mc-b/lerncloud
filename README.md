LernCloud
=========

Das Projekt LernCloud fasst immer wieder verwendete Scripts in einem Projekt zusammen und vermindert *Copy & Paste*.

Dieses Projekt basiert auf den Erfahrungen von [LernKube](https://github.com/mc-b/lernkube) und [LernMAAS](https://github.com/mc-b/lernmaas).

**Das Repository ist im Aufbau und kann Fehler oder Scripts, welche nicht sauber funktionieren, beinhalten!**

Quick Start
-----------

* [Lokaler Computer](intro/)
* [Cloud inkl. LernMAAS](intro/Cloud.md)
* [Terraform](terraform/)
* [Terraform in eigene Module Einbinden](terraform#terraform-in-eigene-module-einbinden)

Für die Einbindung der Scripts in eigene "Cloud-init" Deklarationen siehe [Services](services/) und [Scripts](scripts/).

Hintergrund
-----------

Beim Erstellen von Deklaration/Scripts für "Infrastructure as Code" wiederholen sich bestimmte Muster wieder und wieder.

Z.B. die Installation von Kubernetes ist 1:1 in den Projekten [iotkitv3](https://github.com/iotkitv3/edge), [CNT](https://gitlab.com/ch-tbz-hf/Stud/cnt/-/blob/main/2_Unterrichtsressourcen/K/kubernetes.md) etc. vorhanden.

Dieses Projekt fasst diese Deklaration/Scripts zusammen und vermindert damit den Wartungsaufwand für andere Projekte.

Migration
---------

Migration bestehender [LernKube](https://github.com/mc-b/lernkube) und [LernMAAS](https://github.com/mc-b/lernmaas) Scripts.

* [Migration](migration/)

- - -

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons Lizenzvertrag" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />Dieses Werk ist lizenziert unter einer <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Namensnennung 4.0 International Lizenz</a>.

Copyright (C) mc-b.ch, Marcel Bernet

*Verlinkte Scripte können andere Copyrights beinhalten!*
