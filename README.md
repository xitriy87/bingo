1) Создаем директорию и конф файл /opt/bingo/config.yaml

student_email: a.timoshenko@tssltd.ru
postgres_cluster:
  hosts:
  - address: 10.0.3.37
    port: 5432
  user: bingo
  password: bingo
  db_name: bingo
  ssl_mode: disable
  use_closest_node: false


2)создаем директорию 

 /opt/bongo/logs/359c71e299 перед запуском bingo
 
 
 не забываем сделать ему logrotate (или как вариант ln -s /dev/null /opt/bongo/logs/359c71e299/main.log)
 
 3) Запускаем приложение bingo run_server и оно стартует на *:20061
  
 
4) Dockerfile bingo

FROM alpine
RUN addgroup -g 1000 bingo && adduser -S -u 1000 -G bingo bingo -h /opt/bingo/ && mkdir -p /opt/bongo/logs/359c71e299 && chown -R bingo:bingo /opt/bongo && ln -s /dev/null /opt/bongo/logs/359c71e299/main.log
USER 1000
WORKDIR /opt/bingo/
COPY bingo .
COPY config.yaml .
EXPOSE 20061
CMD ["/bin/sh","-c","./bingo prepare_db"]

FROM alpine
RUN addgroup -g 1000 bingo && adduser -S -u 1000 -G bingo bingo -h /opt/bingo/ && mkdir -p /opt/bongo/logs/359c71e299 && chown -R bingo:bingo /opt/bongo && ln -s /dev/null /opt/bongo/logs/359c71e299/main.log
USER 1000
WORKDIR /opt/bingo/
COPY bingo .
COPY config.yaml .
EXPOSE 20061
CMD ["/bin/sh","-c","./bingo run_server"]


terraform
1) Ansible postgresl

in /home/ubuntu/.asnible.cfg add options - allow_world_readable_tmpfiles=true (sed '1 aallow_world_readable_tmpfiles=true' /ubuntu/.ansible.cfg) 

Apply db and ansible hosts

terraform apply -var-file=var.tfvars -target yandex_compute_instance.bingo-db -target yandex_compute_instance.bingo-ansible

sleep 300

scp ansible role db on ansible-bingo and play it

2) Create bingo prepare_db

terraform apply -var-file=var.tfvars -target yandex_compute_instance.bingo-db-prep -target yandex_resourcemanager_folder_iam_member.bingo-roles

Sleep 600

Delete bingo prepare_db

terraform destroy -var-file=var.tfvars -target yandex_compute_instance.bingo-db-prep -target yandex_iam_service_account.service-accounts -target yandex_resourcemanager_folder_iam_member.bingo-roles

4) Create bingo

terraform plan -var-file=var.tfvars -var="exclude_db_prepare=true"

:> /opt/bongo/logs/359c71e299/main.log

Созда user-data по созданию директории /opt/bingo/logs и дать ей права ubuntu

terraform plan -var-file=var.tfvars -var="exclude_db_prepare=true"


5) Оптимизация Postgresql

а) work_mem 16MB
   shared_memory 512MB
   max_conections = 200

б) создать индексы 


SELECT customers.id, customers.name, customers.surname, customers.birthday, customers.email FROM customers WHERE customers.id IN ($1) ORDER BY customers.surname ASC, customers.name ASC, customers.birthday DESC, customers.id DESC LIMIT 100000;

CREATE INDEX CONCURRENTLY "~customers-a3673268"
  ON customers(
    surname
  , name
  , birthday DESC
  , id DESC
  );



SELECT sessions.id, sessions.start_time, customers.id, customers.name, customers.surname, customers.birthday, customers.email, movies.id, movies.name, movies.year, movies.duration FROM sessions INNER JOIN customers ON sessions.customer_id = customers.id INNER JOIN movies ON sessions.movie_id = movies.id ORDER BY movies.year DESC, movies.name ASC, customers.id, sessions.id DESC LIMIT 100000;

Increase work_mem

SELECT sessions.id, sessions.start_time, customers.id, customers.name, customers.surname, customers.birthday, customers.email, movies.id, movies.name, movies.year, movies.duration FROM sessions INNER JOIN customers ON sessions.customer_id = customers.id INNER JOIN movies ON sessions.movie_id = movies.id WHERE sessions.id IN ($1) ORDER BY movies.year DESC, movies.name ASC, customers.id, sessions.id DESC LIMIT 100000;

CREATE INDEX CONCURRENTLY "~customers-9fccd81c"
  ON customers(id);
CREATE INDEX CONCURRENTLY "~movies-9fccd81c"
  ON movies(id);  
  
CREATE INDEX CONCURRENTLY "~sessions-9fccd81c"
  ON sessions(id);
  
  
7) nginx

proxy_cache_path  /var/cache/nginx  levels=1:2    keys_zone=bingo:10m;

/etc/nginx/sites-enabled/default

upstream bingo {
  server 10.10.100.20:20061 max_fails=1 fail_timeout=2s;
  server 10.10.100.27:20061 max_fails=1 fail_timeout=2s;

}

server {
	listen 80 default_server;
	listen [::]:80 default_server;


	server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                proxy_pass http://bingo$uri;
                expires off;
        }
        location /long_dummy {
                proxy_pass http://bingo/long_dummy;
                proxy_cache     bingo;
                proxy_cache_valid 200 58s;
        }

