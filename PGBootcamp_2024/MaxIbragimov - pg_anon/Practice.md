# Практическая часть использования `pg_anon`

## 1. Создание докер-образа и запуск контейнера

### Вариант 1 - Собрать свой docker образ 
```bash
git clone https://github.com/TantorLabs/pg_anon.git
cd pg_anon/docker
make PG_VERSION=15
docker tag $(docker images -q | head -n 1) pg_anon:pg15
docker run --name pg_anon -d pg_anon:pg15
docker exec -it pg_anon bash
```

### Вариант 2 - Использовать готовый docker образ
```bash
docker pull denjasan/pg_anon:pg15
docker run --name pg_anon -d denjasan/pg_anon:pg15
docker exec -it pg_anon bash
```

## 2. Установка необходимых переменных окружения Python
```bash
export PYTHONPATH=/usr/share/pg_anon
export PYTHONUNBUFFERED=1
```

## 3. Запуск тестов (опционально)
```bash
python3 tests/test_full.py -v
```

## 4. Создвание базы данных - источника
```bash
su - postgres -c "psql -p 5432 -U postgres -c \"CREATE DATABASE source_db;\""

cat > /tmp/db_env.sql << 'EOL'
create table users (
    id bigserial,
    email text,
    login text
);
insert into users (email, login)
select
 'user' || generate_series(1001, 1020) || '@example.com',
 'user' || generate_series(1001, 1020);
EOL

chown postgres:postgres /tmp/db_env.sql
su - postgres -c "psql -p 5432 -d source_db -U postgres -f /tmp/db_env.sql"

su - postgres -c "psql -p 5432 -d source_db -U postgres -c \"SELECT * FROM users;\""
````

## 5. Инициализация служебной схемы БД, содержащей утилиты

```bash
python3 pg_anon.py --mode=init \
	--db-user=postgres \
	--db-user-password=YmTLbLTLxF \
	--db-name=source_db \
	--db-host=127.0.0.1 \
	--db-port=5432
```

## 6. Запуск экспорта анонимизированных данных на диск

### Подготовка файла словаря, для дампа
```bash
cat > /tmp/prepared_sensitive_dict.py << 'EOL'
{
    "dictionary": [
        {
            "schema": "public",
            "table": "users",
            "fields": {
                "email": "md5(\"email\") || '@abc.com'"
            }
        }
    ]
}
EOL
```

### Создание папки для дампа
```bash
mkdir -p /tmp/my_dump
```

### Выполнение дампа
```bash
python3 pg_anon.py --mode=dump \
	--db-host=127.0.0.1 \
	--db-user=postgres \
	--db-user-password=YmTLbLTLxF \
	--db-name=source_db \
	--db-port=5432 \
	--prepared-sens-dict-file=/tmp/prepared_sensitive_dict.py \
	--output-dir=/tmp/my_dump \
	--clear-output-dir
```

### Проверка содержимого в выходной папке
```bash
ls -l /tmp/my_dump
```

## 7. Запуск импорта анонимизированных данных на диск

### Создание БД-приемника
```bash
su - postgres -c "psql -p 5432 -U postgres -c \"CREATE DATABASE target_db;\""
```

### Выполнение импорта, ранее выполненного дампа
```bash
python3 pg_anon.py --mode=restore \
	--db-host=127.0.0.1 \
	--db-port=5432 \
	--db-user=postgres \
	--db-user-password=YmTLbLTLxF \
	--db-name=target_db \
	--input-dir=/tmp/my_dump \
	--verbose=debug
```

### Проверка содержимого итоговой таблицы
```bash
su - postgres -c "psql -p 5432 -d target_db -U postgres -c \"SELECT * FROM users;\""
```

## 8. Проведение сканирования

### Создание мета-словаря
```bash
mkdir -p /usr/share/pg_anon/dict

cat > /usr/share/pg_anon/dict/meta_dict.py << 'EOL'
{
  "field": {
    "rules": [],
    "constants": []
  },
  "skip_rules": [],
  "data_regex": {
    "rules": [
    	"[A-Za-z0-9]+([._-][A-Za-z0-9]+)*@[A-Za-z0-9-]+(\.[A-Za-z]{2,})+"
    ]
  },
  "data_const": {
    "constants": []
  },
  "funcs": {
	"text": "md5(\"%s\") || '@abc.com'"
  }
}
EOL
```

### Запуск сканирования
```bash
python3 pg_anon.py --mode=create-dict \
	--db-user=postgres \
	--db-user-password=YmTLbLTLxF \
	--db-name=source_db \
	--db-host=127.0.0.1 \
	--db-port=5432 \
	--meta-dict-file=meta_dict.py \
	--output-sens-dict-file=/tmp/sens_dict_output.py \
	--processes=2
```

### Сравнение полученного словаря для дампа и словаря, что ранее был создан руками

```bash
cat /tmp/sens_dict_output.py

cat /tmp/prepared_sensitive_dict.py
```
