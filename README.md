LernCloud
=========

Das Projekt LernCloud fasst immer wieder verwendete Scripts in einem Projekt zusammen und vermindert *Copy & Paste*.

Dieses Projekt basiert auf den Erfahrungen von [LernKube](https://github.com/mc-b/lernkube) und [LernMAAS](https://github.com/mc-b/lernmaas).

**Das Repository ist im Aufbau und beinhaltet Fehler oder Scripts welche nicht sauber funktionieren!**

Hintergrund
-----------

Beim Erstellen von Deklaration/Scripts für "Infrastructure as Code" wiederholen sich bestimmte Muster wieder und wieder.

Z.B. die Installation von Kubernetes ist 1:1 in den Projekten [iotkitv3](https://github.com/iotkitv3/edge), [CNT](https://gitlab.com/ch-tbz-hf/Stud/cnt/-/blob/main/2_Unterrichtsressourcen/K/kubernetes.md) etc. vorhanden.

Dieses Projekt fasst diese Deklaration/Scripts zusammen und vermindert damit den Wartungsaufwand für andere Projekte.

Einsatz in eigenen Deklaration/Scripts
--------------------------------------

Das nachfolgende Beispiel zeigt, wie ein Script in die eigenen Cloud-init Scripte integriert werden kann.

    #cloud-config
    runcmd:
     - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/nfs.sh | bash -

Welche [Services](services/) und [Scripte](scripts/) vorhanden, siehe entsprechende Unterverzeichnisse.

Im Verzeichnis [Modules](modules/) befindet sich, sofort einsatzfähige Beispiele, für immer wieder verwendetete Module. 

- - -

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons Lizenzvertrag" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />Dieses Werk ist lizenziert unter einer <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Namensnennung 4.0 International Lizenz</a>.
