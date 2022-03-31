#!/bin/bash
#
#   Stellt ein einfaches Web UI zu Kubernetes zur Verfuegung
#

sudo apt install -y apache2 jq markdown
sudo a2enmod cgi
sudo systemctl restart apache2

sudo chmod +x /opt/lernmaas/cgi-bin/*
sudo cp /opt/lernmaas/cgi-bin/* /usr/lib/cgi-bin/
sudo ln -s /home/ubuntu/data /var/www/html/data

# wenn WireGuard installiert - Wireguard IP als ADDR Variable setzen
export ADDR=$(ip -f inet addr show wg0 | grep -Po 'inet \K[\d.]+')
[ "${ADDR}" == "" ] && { export ADDR=$(hostname -f); }
[ "$(hostname -I | cut -d ' ' -f 1)" == "10.0.2.15" ] && { export ADDR=$(hostname -I | cut -d ' ' -f 2); }

# index.html
cat <<%EOF% | sudo tee /var/www/html/index.html
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>$(hostname) Web UI</title>
<link rel="shortcut icon" href="https://kubernetes.io/images/favicon.png">
<meta charset="utf-8" content="">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these 
        
    <!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
    integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css"
    integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">
</head>

<body>
    <div class="container">
        <h1 class="center">$(hostname) Web UI</h1>
        <form class="navbar-form navbar-left" method="POST" action="">
            <div class="form-group">
                <!-- Tabs -->
                <ul class="nav nav-tabs">
                    <li class="active"><a data-toggle="tab" href="#Intro">Intro</a></li>
%EOF%

if [ -f /home/ubuntu/.ssh/passwd ] 
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html
                    #<li><a data-toggle="tab" href="#Accessing">Accessing</a></li>
%EOF%
fi

cat <<%EOF% | sudo tee -a /var/www/html/index.html                  
                    <li><a data-toggle="tab" href="#Services">Services</a></li>
                    <li><a data-toggle="tab" href="#Pods">Pods</a></li>
                    <li><a data-toggle="tab" href="#Cluster">Cluster-Info</a></li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                    <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                </ul>

                <div class="tab-content">
                    <!--  Intro -->
                    <div id="Intro" class="tab-pane fade in active">
                         $(curl -sfL h $1 | markdown | envsubst)
                    </div>  
%EOF%

if [ -f /home/ubuntu/.ssh/passwd ] 
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html                  
                    <!--  Access -->
                    <div id="Accessing" class="tab-pane fade">
                        <h2>Zugriff auf den Server</h2>
                        
                        <h3>User / Password</h3>
                        <p>Der User ist <code>ubuntu</code>, dass Password steht in der Datei <a href="/data/.ssh/passwd">/data/.ssh/passwd</a>.</p>
                        <p>Einloggen mittels</p>
                        <pre><code>ssh ubuntu@${ADDR}</code></pre>
                        
                        <h3>SSH</h3>
                        <p>Auf der Server kann mittels <a href="https://wiki.ubuntuusers.de/SSH/">ssh</a> zugegriffen werden.</p>
                        <p>Der private SSH Key ist auf dem Installierten Server unter <a href="/data/.ssh/id_rsa">/data/.ssh/id_rsa</a> zu finden. Downloaden und dann wie folgt auf den Server einloggen:</p>
                        <pre><code>ssh -i id_rsa ubuntu@${ADDR}</code></pre>
                        <p><strong>Hinweis</strong>: Windows User verwenden <a href="https://www.bitvise.com/">bitvise</a> und legen den privaten SSH Key im "Client key manager" ab.</p>                    
                    
                        <h3>Kubernetes CLI</h3>
                        <p>Die Kubernetes Konfigurationsdatei von <a href="/data/.ssh/config">hier</a> downloaden.</p> 
                        <p>Anschliessend das <code>kubectl</code> CLI, von der <a href="https://kubernetes.io/de/docs/tasks/tools/install-kubectl/#installation-der-kubectl-anwendung-mit-curl">Kubernetes Site</a> downloaden.</p>
                        <p>Die Pods können dann wie folgt angezeigt werden:</p>
                        <pre><code>kubectl --kubeconfig config get pods --all-namespaces</code></pre>
%EOF%

if [ "$2" != "minimal" ]
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html                  
                        <h3>Dashboard</h3>
                        <p>Für den Zugriff auf das Dashboard benötigen wir einen Zugriffstoken und müssen den Kubernetes API-Port zum lokalen Notebook/PC weiterleiten.</p>
                        <p>Weiterleitung des API Ports von Kubernetes zum lokalen Notebook/PC</p>
                        <pre><code>kubectl --kubeconfig config proxy                        </code></pre>
                        <p>Aufruf des Dashboards mittels <a href="http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/">http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/</a>. </p>
                        <p>Der Token ist auf dem Tab <strong>Cluster-Info</strong> ersichtlich. </p>
                           
                        <h3>Weave Scope</h3>
                        <p><a href="https://www.weave.works/oss/scope/">Weave Scope</a> visualisiert die Beziehungen zwischen den Ressourcen eines Kubernetes Clusters. </p>
                        <p><a href="https://www.weave.works/oss/scope/">Weave Scope</a> ist Standardmässig installiert und kann nach dem weiterleiten des Ports über <a href="http://localhost:4040">localhost:4040</a> angesprochen werden.</p>
                        <p>Weiterleitung des Weave Scope Ports zum lokalen Notebook/PC</p>
                        <pre><code>kubectl --kubeconfig config port-forward -n weave deployment/weave-scope-app 4040                        </code></pre>
%EOF%
fi 

cat <<%EOF% | sudo tee -a /var/www/html/index.html                                          
                        <h3>Service-Ports auf den lokalen Notebook weiterleiten</h3>
                        <p>Mit <a href="https://kubefwd.com/">kubefwd</a> werden Kubernetes-Dienste, die in einem Remotecluster ausgeführt werden, an eine lokale Workstation weitergeleitet, wodurch die Entwicklung von Anwendungen erleichtert wird, die mit anderen Services kommunizieren.</p>
                        
                        <p>Anwendung</p>
                        <ul><li>Programm von <a href="https://github.com/txn2/kubefwd/releases">kubefwd</a> downloaden</li>
                        <li>Consolen Fenster als Administrator starten, bzw. bei Linux <code>sudo</code> voranstellen</li>
                        <li>Alle Services der <code>default</code> Kubernetes Namespace zum Notebook weiterleiten und <code>hosts</code> Datei nachführen</li></ul>
                        
                        <pre><code>kubefwd --kubeconfig config services</code></pre>
                                                
                    </div>   
%EOF%
fi

cat <<%EOF% | sudo tee -a /var/www/html/index.html                  
                    <!--  Services -->
                    <div id="Services" class="tab-pane fade">
                        <br/>
                         <iframe frameborder="0" scrolling="no" width="100%" height="3200px" onload="scroll(0,0);" src="/cgi-bin/services">
                         </iframe>
                    </div>
                    <!--  Pods -->
                    <div id="Pods" class="tab-pane fade">
                        <br/>
                         <iframe frameborder="0" scrolling="no" width="100%" height="3200px" onload="scroll(0,0);" src="/cgi-bin/pods">
                         </iframe>
                    </div>
                    <!--  Cluster Info -->
                    <div id="Cluster" class="tab-pane fade">
                        <br/>
                         <iframe frameborder="0" scrolling="no" width="100%" height="3200px" onload="scroll(0,0);" src="/cgi-bin/cluster">
                         </iframe>
                    </div>                    
                </div>                    

                <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
                <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js" type="text/javascript"></script>
                <!-- Latest compiled and minified JavaScript -->
                <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
                    integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"
                    type="text/javascript"></script>
                 <script>
                // strip / bei Wechsel Port
                document.addEventListener('click', function(event) {
                  var target = event.target;
                  if (target.tagName.toLowerCase() == 'a')
                  {
                      var port = target.getAttribute('href').match(/^:(\d+)(.*)/);
                      if (port)
                      {
                         target.href = port[2];
                         target.port = port[1];
                      }
                  }
                }, false);
                </script>
            </div>
        </form>
    </div>
</body>
</html>
%EOF%

 
