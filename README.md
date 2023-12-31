## Bingo app

1. **Создаем конфигупационный файл для bingo config.yaml**
```
student_email: email.com
postgres_cluster:
  hosts:
  - address: 10.10.10.20 # адрес сервера db можно выставлять после развертывания db через terrform
    port: 5432
  user: bingo
  password: bingo
  db_name: bingo
  ssl_mode: disable
  use_closest_node: false
```  
2. **Dockerfile bingo**
```
FROM alpine:3.18
RUN addgroup -g 1000 bingo && adduser -S -u 1000 -G bingo bingo -h /opt/bingo/  \
&& mkdir -p /opt/bongo/logs/359c71e299 && chown -R bingo:bingo /opt/bongo \
&& apk add curl && rm -rf /var/cache/apk/*
USER 1000
WORKDIR /opt/bingo/
COPY bingo .
COPY config.yaml .
EXPOSE 20061
CMD ["/bin/sh","-c","./bingo prepare_db ; ./bingo run_server"]
```
Собираем образ контейнера
```
docker build . -t  bingo:v1
```
Будем использовать registry yandex, для этого создаем в своем каталоге container registy и загружаем туда собранный контейнер
```
docker tag bingo:v1 cr.yandex/crp10pq00qo5b4oh3tvv/bingo:v1
docker push cr.yandex/crp10pq00qo5b4oh3tvv/bingo:v1
```
И прописываем его в качестве image в файле docker-compose.

3. **Разворачиваем через terraform сервера db и ansible**
```
$terraform apply -var-file=var.tfvars -target yandex_compute_instance.bingo-db -target yandex_compute_instance.bingo-ansible
```

4. **Копируем ansible директорию на сервер ansible (прописываем в файле hosts адрес нашего db сервера)**
```
$scp -i "ключ" -r ansible/ ubuntu@"внешний ip-адрес ресурса ansible"
```
5. **Проигрываем плайбук playbook-db.yml на ansible хосте**
```
$ansible-playbook -i hosts playbook-db.yml
```
6. **Через terraform разворачиваем ресурс bingo-db-prepare для заполнения базы данных**
```
$terraform apply -var-file=var.tfvars -target yandex_compute_instance.bingo-db-prep -target yandex_resourcemanager_folder_iam_member.bingo-roles
```
Ждем пока база заполнится дынными

7. **Удаляем ненужный больше ресурс bingo-db-prepare**
```
$terraform destroy -var-file=var.tfvars -target yandex_compute_instance.bingo-db-prep
```
8. **Производим настройку быза данных для ускорения выполнения запросов** Д
Для этого проигрываем плайбук playbook-db-tune.yml на ansible хосте
```
$ansible-playbook -i hosts playbook-db.yml
```
9. **Разворачиваем через terraform ресурсы bingo и lb**
```
$terraform plan -var-file=var.tfvars -var="exclude_db_prepare=true"
``` 
  
10. **Разворачиваем на ресурсе lb наш load balancer**
Для этого проигрываем плайбук playbook-lb.yml на ansible хосте, предварительно указав ip-адрес lb ресурса в файле hosts
```
lb ansible_host=10.10.10.10
```
И указав переменные с адресами ресурсов bingo и server_name в файле с переменными роли lb (lb/vars/main.yml):
```
BINGO_IP_1: "10.10.100.6"
BINGO_IP_2: "10.10.100.23"
SERVER_NAME: "bingo.xitriy87test.ru"
```
Добавляем ключи SSL в директорию роли lb/files/

```
privkey.pem
fullchain.pem
```

```
$ansible-playbook -i hosts playbook-lb.yml
```
11. **Далее настраиваем DNS-запись типа A для вашего домена с указанием внешнего ip-адреса ресурса lb**

12. **Удаляем ansible хост**

```
$terraform destroy -var-file=var.tfvars -target yandex_compute_instance.bingo-ansible
```

