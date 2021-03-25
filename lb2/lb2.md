# LB2 Dokumentation
## Inhaltsverzeichnis
- [Einleitung](##Einleitung)
    - [Sicherheit](###Sicherheit)
- [Grafische Übersicht](##GrafischeÜbersicht)
    - [Beschreibung](###Beschreibung)
- [Erklärung Code](##ErklärungCode)
- [Testverfahren](##Testverfahren)
- [Quellenangaben](##Quellenangaben)

## Einleitung
In diesem Projekt handelt es sich um IaC, wo ich mit einem Vagrant-File eine Infrastruktur mit einem Unix System aufsetze. Auf diesem Server installiere ich die zwei bekanntesten Unix Webserver-Softwares Apache und NGINX. Den Apache setze ich als Webserver auf und den NGINX konfigurere ich als einen Reverse-Proxy für die Sicherheit.

### Sicherheit
Um die Verbindung zwischen den Client und dem Server zu sichern, werde ich den Zugriff über HTTPS mit einem selbst erstellen Zertifikat gewährleisten.

## Grafische Übersicht
```
+---------------------------------------------------------------+
! Notebook - Schulnetz 10.x.x.x und Privates Netz 192.168.55.1  !                 
! Port: 8080 (192.158.55.101:80)                                !	
!                                                               !	
!    +--------------------+          +---------------------+    !
!    ! Web Server         !          ! Datenbank Server    !    !       
!    ! Host: web01        !          ! Host: db01          !    !
!    ! IP: 192.168.55.101 ! <------> ! IP: 192.168.55.100  !    !
!    ! Port: 80           !          ! Port 3306           !    !
!    ! Nat: 8080          !          ! Nat: -              !    !
!    +--------------------+          +---------------------+    !
!                                                               !	
+---------------------------------------------------------------+
```
> *Die Grafische Darstellung soll das Verhältnis zwischen den Systemen und Verbindungen aufzeigen*
### Beschreibung
Der Host-Client geht auf den Browser und tippt "https://localhost:8009" in die Suchzeile. Der Host-Client greift mit dem Port 8009 auf die NAT-Schnittstelle des Gast-Systems. Das Port-Forwarding leitet den Port 8009 auf den Port 443. 

> Der Reverse-Proxy (NGINX) baut die Verbindung via den Port 443 auf.
> Die Verbindung wird verschlüsselt mit einem Self-Signed Zertifikat.
> Der Reverse-Proxy leitet dann das wieder an den Port 8080.
> Der Webserver (Apache) empfängt es und kann auf die Anfrage vom Host-Client mit der Webseite antworten.

## Erklärung Code
### Code
Gesamter Code:
```
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest:443, host:8009, auto_correct: true
  config.vm.synced_folder ".", "/var/www/html"  
config.vm.provider "virtualbox" do |vb|
  vb.memory = "512"  
end
config.vm.provision "shell", inline: <<-SHELL
  #Install Apache
  sudo apt-get update
  sudo apt-get -y install apache2
  
  #Conf Apache
  sudo sed -i 's/80/8080/g' /etc/apache2/sites-available/000-default.conf
  sudo sed -i 's/80/8080/g' /etc/apache2/ports.conf
  sudo systemctl restart apache2
  
  #Firewall
  sudo ufw enable
  sudo ufw allow proto tcp from any to any port 443,8080
  sudo ufw reload

  #Install NGINX
  sudo apt-get -y install nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
  
  #Zertifikat erstellen
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=CH/ST=Zuerich/L=Zuerich/O=TBZ/CN=localhost" -keyout /etc/nginx/cert.key  -out /etc/nginx/cert.crt
  sudo cp /etc/nginx/cert.crt /var/www/html/cert.crt
  #NGINX Konfiguation
  sudo rm -rf /etc/nginx/sites-enabled/default
  sudo cp /var/www/html/nginx_config.txt /etc/nginx/sites-enabled/default
  sudo systemctl restart nginx

SHELL
end
```
#### Vagrant-VM Konfiguration
```
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest:443, host:8009, auto_correct: true
  config.vm.synced_folder ".", "/var/www/html"  
config.vm.provider "virtualbox" do |vb|
  vb.memory = "512"  
end
config.vm.provision "shell", inline: <<-SHELL ...
```
Hier bestimmen wir die Konfigurationen für Vagrant zur Erstellung der Virtuellen Maschine.
Folgende Daten währden gesetzt:
* `config.vm.box = "ubuntu/xenial64"` gibt die Vagrant-Box an. In dieser Vagrant-Box ist die Distribution Ubuntu.
* `config.vm.network "forwarded_port", guest:443, host:8009, auto_correct: true` Hier geben wir die Schnittstelle konfiguriert.
> Wir bestimmen das NAT-Interface mit dem *"forwarded_port"*. Mit dem *guest:443* und *host:8009* geben wir die Informationen zu dem Portforwarding. Beim Parameter *auto_correct: true* wird einfach der Ziel-Port angepasst, falls der angegeben Port (8009) von einem Dienst zu verfügung steht.
* `config.vm.synced_folder ".", "/var/www/html"` erstellt eine Synchornisation zwischen den beiden Verzeichnissen.
* Mit `config.vm.provider "virtualbox"...` erstellen wir die tatsächliche Virtuelle Maschine. Der Parameter `vb.memory = "512"` gibt das RAM der VM an.
* Die Zeile `config.vm.provision "shell", inline: <<-SHELL` erlaubt uns unsere Unix-Befehle beim installieren der VM, gleich abzuspielen.
#### Apache Installation
```
  sudo apt-get update
  sudo apt-get -y install apache2
```
> Mit diesem Befehlen installieren wir Apache also Webservice.

#### KOnfiguration von Apache
Um den Server zu konfiguriren, werden wir Dateien ändern.
```
    sudo sed -i 's/80/8080/g' /etc/apache2/sites-available/000-default.conf
    sudo sed -i 's/80/8080/g' /etc/apache2/ports.conf
```
> Wir wollen mit der Konfiguration, den Port von Apache ändern. Das machen wir in der ports.conf und 000-default.conf-Datei. Vom Standart-Port 80 setzen wir ihn auf Port 8080.
> Der Befehl "sed" ermöglicht uns gezielt den Inhalt von einer Datei zu ändern. Wir ändern mit dem Befehl den Wert 80 in 8080 um.

#### Firewall Regeln
Wir erstellen Firewall-Regeln für den Zugriff zu den Diensten.
```
  sudo ufw enable
  sudo ufw allow proto tcp from any to any port 443,8080
  sudo ufw reload
```
> Mit diesen Befehlen erlauben wir die Port 8080 und 443 auf unserem System.

#### Installation NGINX
```
  sudo apt-get -y install nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
```
> Wir installieren NGINX.

#### Zertifikat
```
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=CH/ST=Zuerich/L=Zuerich/O=TBZ/CN=localhost" -keyout /etc/nginx/cert.key  -out /etc/nginx/cert.crt
  sudo cp /etc/nginx/cert.crt /var/www/html/cert.crt
```
> OpenSSL bietet uns die Möglichkeit Zertifikate zu erstellen. 
Mit diesem Befehl erstelle ich interaktiv ein Self-Signed Zertifikat. Danach kopieren wir das CA, um es später bei unseren zu installieren.

### Konfiugrationsdatei nginx_conf.txt
´´´
server {
        listen 80;
        return 301 https://$host$request_uri;
    }


server {

    listen 443 ssl;
    server_name localhost;

    ssl_certificate           /etc/nginx/cert.crt;
    ssl_certificate_key       /etc/nginx/cert.key;

    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;

    location / {


      proxy_set_header        Host $host;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;

      proxy_pass          http://localhost:8080;
    }
  }
´´´
> *Das ist die Konfigurations-Datei vom Reverse-Proxy*

#### SSL
```
listen 443 ssl;
    server_name localhost;

    ssl_certificate           /etc/nginx/cert.crt;
    ssl_certificate_key       /etc/nginx/cert.key;

    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
```
> Hier geben wir die Parameter zu der verschlüsselten Verbindung. Wir sagen der Datei wo sich das Zertifikat und Schlüssel finden `ssl_certificate   /etc/nginx/cert.crt;` und `ssl_certificate_key   /etc/nginx/cert.key;`. Wir geben noch weiter Angaben zu der Kommunikation.

#### Reverse-Proxy
```
      proxy_set_header        Host $host;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;

      proxy_pass          http://localhost:8080;
```
> Das sind die nötigen Konfigurationen für den Reverse-Proxy.

```
  sudo rm -rf /etc/nginx/sites-enabled/default
  sudo cp /var/www/html/nginx_config.txt /etc/nginx/sites-enabled/default
  sudo systemctl restart nginx

```
Zum Schluss ersetzen wir die Dateien und starten den NGINX neu. 
## Testverfahren
Zum testen, habe ich das Vagrant-File angespielt und die 

Testfall 1:
| Testfall-ID              | 1            |
|:--------------------:|:--------------------:|
| Soll-Zustand       |Der Client sollte auf die Webseite zugreiffen können.|

Ist-Zustand:

![Apache-Website]()


| Testfall-ID              | 2            |
|:--------------------:|:--------------------:|
| Soll-Zustand       |Die Verbindung sollte mit dem Zertifikat verschlüsselt sein.|

Ist-Zustand:

![Zertifikat]()

## Quellenangaben
- [NGINX](https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-as-a-web-server-and-reverse-proxy-for-apache-on-one-ubuntu-18-04-server)
- [NGINX SSL](https://willy-tech.de/https-in-nginx-einrichten/) 
- [OpenSSL](https://www.grund-wissen.de/linux/server/openssl.html)
- [Vagrant]()