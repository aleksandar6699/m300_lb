# Dokumentation LB3
## Inhaltsverzeichnis
- [Einleitung](#Einleitung)
- [Grafische Übersicht](#gu)
    - [Beschreibung](#Beschreibung)
- [Erklärung Konfiguration](#ec)
    - [Dockerfile](#Dockerfile)
    - [Docker-Compose](#Docker-Compose)
        - [Datenbank](#Datenbank)
        - [phpMyAdmin](#phpMyAdmin)
        - [Wordpress](#Wordpress)
- [Testverfahren](#Testverfahren)
- [Quellenangaben](#Quellenangaben)

## Einleitung

In diesem Projekt erstelle ich die eine Umgebung für Entwickler. Ich erstelle dabei mit dem Dockerfile und Docker-Compose drei Container mit jeweis verschiedenen Diensten.

## Grafische Übersicht <a name="gu"></a>

Eine grafische Übersicht vom Aufbau der Struktur:
```
    +-----------------------------------------------------------------------------+
    ! +----------------------+ +------------------------------+ +---------------+ !       
    ! | Container: Wordpress | | Container: phpmyadmin        | | Container: db | !
    ! | Image : Wordpress    | | Image: phpmyadmin/phpmyadmin | | Image: mysql  | !
    ! | Tag: latest          | | Tag: keine (latest)          | | Tag: 5.7      | !
    ! | Port: 8000:80        | | Port: 8050:80                | |               | !
    ! +----------------------+ +------------------------------+ +---------------+ !
    !             |                            |                        |         !
    ! +-------------------------------------------------------------------------+ !
    ! | Netzwerk-Verbindung                                                     | !
    ! | Name: wpnw                                                              | !
    ! +-------------------------------------------------------------------------+ !
    ! Container-Engine: Docker                                                    !	
    +-----------------------------------------------------------------------------+
```


### Beschreibung
Dabei wird Wordpress, phpMyAdmin und einen MySQL-Datenbank. Alle diese Dienste befinden sich im gleichen Netzwerk und sind miteinander in Verbindung.
Wir verbinden unseren Dienst Wordpress mit der Datenbank und mit dem phpMyAdmin können wir die Datenbanken bearbeiten.

## Erklärung Konfiguration <a name="ec"></a>
In diesem Teil werden die zwei Datein: Dockerfile und Docker-Compose erklärt:

### Dockerfile
In diesem Dockerfile bestimmen wir die Angaben für den Dienst Wordpress.
```
FROM wordpress:latest
ENV WORDPRESS_DB_HOST=db:3306
ENV WORDPRESS_DB_USER=wordpress
ENV WORDPRESS_DB_PASSWORD=wordpress
ENV WORDPRESS_DB_NAME=wordpress
```
Mit dem `FROM wordpress:latest` bestimmen wir welches Image wir nehmen wollen. Der Tag *:latest* bestimmt die Version des Dienstes.

Der Parameter `ENV ...` geben wir dem Dienst noch die Umgebungsvariablen. Mit diesen Variabel geben wir den Wordpress an, dass wir uns mit der MySQL-Datenbank verbinden sollen.

### Docker-Compose
In diesem Abschnitt erkläre ich die **Docker-Compose** Datei.

#### Datenbank
Das ist der Abschnitt zum Container zu der Datenbank:
```
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    networks:
      - wpnw
```
> `image: mysql:5.7` bestimmt das Image mit dem wir den Container aufbauen. Der Tag *:5.7* bestimmt die Version des Dienstes.

> `environment:` bestimmt die Umgebungsvariablen vom Container. So bestimmen wir die Passwörter und die Benutzer.

> Mit dem Parameter `networks:` bestimmen wir das Netzwerk, zu welchem der Container gehört. Dieser Container gehört somit zu dem Netzwerk *wpnw*.

#### phpMyAdmin
Das ist der Docker-Compose Abschitt zum Container phpMyAdmin:
```
  phpmyadmin:
    depends_on:
      - db
    image: phpmyadmin/phpmyadmin
    restart: always
    ports:
      - '8050:80'
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: password
    networks:
      - wpnw
```
> Beim `depends_on:` geben wir die Anhängigkeit zu einem Container. Dort geben wir an, dass der Container vom *db* abhängig ist.

> `image: phpmyadmin/phpmyadmin` bestimmt das Image mit dem wir den Container aufbauen.

> Mit `ports:` und dem Parameter `- '8050:80'` Forwarden wir den Port 8050 von der VM zum Port 80 auf dem Container.

> `environment:` bestimmt die Umgebungsvariablen vom Container.

> Der Parameter `networks:` bestimmt in welchen Netzwerk der Container sich befindet. Dieser Container befindet sich im Netzwerk *wpnw*

#### Wordpress
Das ist der Abschnitt zum Container vom Wordpress:
```
  wordpress:
    depends_on:
      - db
    build: .
    ports:
      - '8000:80'
    restart: always
    networks:
      - wpnw
```
> Beim `depends_on:` geben wir die Anhängigkeit zu einem Container. Dort geben wir an, dass der Container vom *db* abhängig ist.

> Mit dem Parameter `build: .` sagen wir dem Docker-Compose, er soll das Image mit dem Dockerfile aufbauen. Der Punkt weisst an, dass sich das File im aktuellen Verzechnis befindet.

> Mit `ports:` und dem Parameter `- '8000:80'` Forwarden wir den Port 8000 von der VM zum Port 80 auf dem Container.

> Der Parameter `networks:` bestimmt in welchen Netzwerk der Container sich befindet. Dieser Container befindet sich im Netzwerk *wpnw*

## Testverfahren

Testfall 1:
| Testfall-ID              | 1            |
|:--------------------:|:--------------------:|
| Soll-Zustand       |Ich kann mich auf den Port 8000 verbinden und ein Login für Wordpress erstellen und anmelden.|

Ist-Zustand:

![Wordpress](https://github.com/aleksandar6699/m300_lb/blob/6ead06e054c73edfb4603043f9259e4d9a06c6dc/lb3/image/wordpress.JPG)

| Testfall-ID              | 2            |
|:--------------------:|:--------------------:|
| Soll-Zustand       |Ich kann auf den Port 8050 zugreifen und mich anmelden im phpMyAdmin.|

Ist-Zustand:

![phpMyAdmin](https://github.com/aleksandar6699/m300_lb/blob/6ead06e054c73edfb4603043f9259e4d9a06c6dc/lb3/image/phpmyadmin_login.JPG)

![Root](https://github.com/aleksandar6699/m300_lb/blob/6ead06e054c73edfb4603043f9259e4d9a06c6dc/lb3/image/root_access.JPG)

## Quellenangaben

- [Wordpress](https://hub.docker.com/_/wordpress)
- [phpMyAdmin](https://hub.docker.com/r/phpmyadmin/phpmyadmin)
- [MySQL](https://hub.docker.com/_/mysql) 
