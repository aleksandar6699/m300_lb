Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest:80, host:8080, auto_correct: true
  config.vm.synced_folder ".", "/var/www/html"  
config.vm.provider "virtualbox" do |vb|
  vb.memory = "512"  
end
config.vm.provision "shell", inline: <<-SHELL
  # Packages vom lokalen Server holen
  # sudo sed -i -e"1i deb {{config.server}}/apt-mirror/mirror/archive.ubuntu.com/ubuntu xenial main restricted" /etc/apt/sources.list 
  
  #Install Apache
  sudo apt-get update #
  sudo apt-get -y install apache2 #
  
  #Conf Apache
  sudo sed -i's/80/8080/g' /etc/apache2/sites-available/000-default.conf #
  sudo sed -i 's/80/8080/g' /etc/apache2/ports.conf #
  sudo systemctl restart apache2 #
  
  #Firewall
  sudo ufw enable #
  sudo ufw allow proto tcp from any to any port 80,443,8080 #
  sudo ufw reload #

  #Install NGINX
  sudo apt-get -y install nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
  
  #Zertifikat erstellen
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=CH/ST=Zuerich/L=Zuerich/O=TBZ/CN=localhost" -keyout /etc/nginx/cert.key  -out /etc/nginx/cert.crt
  
#NGINX Konfiguation
sudo rm -rf /etc/nginx/sites-enabled/default
sudo printf "server { \n
        listen 80;\n
        return 301 https://$host$request_uri;\n
    }\n\n

server {\n
\n
    listen 443 ssl; \n
    server_name localhost ;\n
\n
    ssl_certificate           /etc/nginx/cert.crt;\n
    ssl_certificate_key       /etc/nginx/cert.key;\n
\n
    ssl_session_cache  builtin:1000  shared:SSL:10m;\n
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;\n
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;\n
    ssl_prefer_server_ciphers on;\n
\n
    access_log /var/log/nginx/access.log;
\n
    location / { \n
\n

      proxy_set_header        Host $host;\n
      proxy_set_header        X-Real-IP $remote_addr;\n
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;\n
      proxy_set_header        X-Forwarded-Proto $scheme;\n
\n
      proxy_pass          http://localhost:8080;\n
      #proxy_read_timeout  90;\n
\n
      #proxy_redirect      http://localhost:8080 https://jenkins.domain.com;\n
    }\n
  }\n" >> /etc/nginx/sites-enabled/default
  
  sudo systemctl restart nginx
#VAR problem


SHELL
end