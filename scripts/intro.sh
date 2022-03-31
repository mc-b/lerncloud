#!/bin/bash
#
#   Hilfsscript fuer eine Intro Seite
#
#   Installiert:
#   - Apache Web Server
#   - Umwandler Markdown - HTML
#
#   Beschreibt:
#   - die Zugangsarten zur VM
#   - embedded README.md, ACCESSING.md und SERVICES.md, aus dem Repository, in die Seite ein
#
#   Umgebungsvariablen
#   ${ADDR} - IP-Adresse der VM. Wenn WireGuard installiert hat diese IP Vorrang

sudo apt-get install -y apache2 jq markdown

# wenn WireGuard installiert - Wireguard IP als ADDR Variable setzen
export ADDR=$(ip -f inet addr show wg0 | grep -Po 'inet \K[\d.]+')
[ "${ADDR}" == "" ] && { export ADDR=$(hostname -f); }

# Home Verzeichnis unter http://<host>/data/ verfuegbar machen, wenn Zugriff via Password erlaubt
if [ -f /home/ubuntu/.ssh/passwd ] || [ -f ACCESSING.md ]
then
    mkdir -p /home/ubuntu/data/
    sudo ln -s /home/ubuntu/data /var/www/html/data
fi

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

if [ -f /home/ubuntu/.ssh/passwd ] || [ -f ACCESSING.md ]
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html
                    #<li><a data-toggle="tab" href="#Accessing">Accessing</a></li>
%EOF%
fi

if [ -f SERVICES.md ]
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html
                    <li><a data-toggle="tab" href="#Services">Services</a></li>
%EOF%
fi 

cat <<%EOF% | sudo tee -a /var/www/html/index.html
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
                        $(markdown README.md | envsubst)
                    </div> 
%EOF%
                    
if [ -f ACCESSING.md ]      
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html                                        
                    <!--  Access -->
                    <div id="Accessing" class="tab-pane fade">
                        $(markdown ACCESSING.md | envsubst)
                    </div>
%EOF%
elif [ -f /home/ubuntu/.ssh/passwd ]
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html                                        
                    <!--  Access -->
                    <div id="Accessing" class="tab-pane fade">
                        <h2>Zugriff auf den Server</h2>
                        <p><strong>User / Password</strong></p>
                        <p>Der User ist <code>ubuntu</code>, dass Password steht in der Datei <a href="/data/.ssh/passwd">/data/.ssh/passwd</a>.</p>
                        <p>Einloggen mittels</p>
                        <pre><code>ssh ubuntu@${ADDR}</code></pre>
                        <p><strong>SSH</strong></p>
                        <p>Auf der Server kann mittels <a href="https://wiki.ubuntuusers.de/SSH/">ssh</a> zugegriffen werden.</p>
                        <p>Der private SSH Key ist auf dem Installierten Server unter <a href="/data/.ssh/id_rsa">/data/.ssh/id_rsa</a> zu finden. Downloaden und dann wie folgt auf den Server einloggen:</p>
                        <pre><code>ssh -i id_rsa ubuntu@${ADDR}</code></pre>
                        <p><strong>Hinweis</strong>: Windows User verwenden <a href="https://www.bitvise.com/">bitvise</a> und legen den privaten SSH Key im "Client key manager" ab.</p>                    
                    </div>
%EOF%
fi                     

if [ -f SERVICES.md ]
then
cat <<%EOF% | sudo tee -a /var/www/html/index.html                                        
                    <!--  Services -->
                    <div id="Services" class="tab-pane fade">
                        $(markdown SERVICES.md | envsubst)
                    </div>
                </div>  
%EOF%
fi                                 

cat <<%EOF% | sudo tee -a /var/www/html/index.html                                        
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

if [ -f /home/ubuntu/.ssh/passwd ] || [ -f ACCESSING.md ]
then
    sudo chmod -R g=u,o=u /home/ubuntu/data/
fi
