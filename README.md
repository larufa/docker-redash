# Docker-redash

## Mysql + Redash on Docker

### 準備

* docker ( >= 1.12 ) がセットアップされていること
* 次のコマンドで必要なものを準備します
  * 動作は `-n` オプションを付けて確認出来るので気になる方は試してみて下さい
      * docker-compose の取得
      * redash で使用する postgres のセットアップ

```bash
$ make install setup
```

### 動かし方

`PORT` 番号は自分の環境でバインド可能なものを指定すること。

```bash
$ make up PORT=8080
```

次の URL にアクセスします（PORT 番号は適宜変更すること）。

[http://localhost:8080/](http://localhost:8080/)

* Email: `admin@example.com`
* Password: `redash`


### コンテナでコマンドを実行する

2つの方法があります。

例えば mysql container で動いているプロセスを見たい場合、


その1

```bash
$ make debug/mysql
root@6a897d20ed22:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
mysql        1  0.0  9.8 1270724 200952 ?      Ssl  11:42   0:01 mysqld
root      2658  0.1  0.1  20252  3036 pts/0    Ss   12:42   0:00 bash
root      2670  0.0  0.1  17504  2068 pts/0    R+   12:42   0:00 ps aux
```

その2（その1 では container に入るために bash が実行されています）

```bash
$ make exec/mysql COMMAND="ps aux"
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
mysql        1  0.0  9.8 1270724 200952 ?      Ssl  11:42   0:01 mysqld
root      2709  0.0  0.1  17504  2116 pts/0    Rs+  12:43   0:00 ps aux
```

### カスタム

実行時に環境変数を通してパラメータを渡すことが出来ます。

詳しくは Makefile を見て下さい。

※ `REDASH_CONTAINER_NAME` のみ **redash** で固定です（これは redash/nginx の nginx の設定ファイルを見れば分かります）

```bash
$ grep -E "^[A-Z]+.*" Makefile | sed -e 's/[^A-Z] *://g' | column -t -s "="
NGINX_VERSION                       latest
MYSQL_VERSION                       5.7
REDASH_VERSION                      latest
NGINX_CONTAINER_NAME                nginx
MYSQL_CONTAINER_NAME                mysql
POSTGRES_CONTAINER_NAME             postgres
REDASH_CONTAINER_NAME               redash
REDASH_WORKER_CONTAINER_NAME        worker
REDIS_CONTAINER_NAME                redis
PORT                                8080
MYSQL_ROOT_PASSWORD                 redash
MYSQL_DATABASE                      redash
MYSQL_USER                          redash
MYSQL_PASSWORD                      redash
REDASH_ADMIN_PASSWORD               redash
REDASH_ORG_NAME                     treasure
REDASH_COOKIE_SECRET                $(shell pwgen 32 -1)
REDASH_WOKERS_COUNT                 2
BIN_DIR                             $(shell pwd)/bin
DOCKER_COMPOSE_YAML                 docker-compose.yml
DOCKER_CMD                          $(shell which docker)
DOCKER_COMPOSE                      $(shell pwd)/bin/docker-compose
DOCKER_COMPOSE_CMD                  $(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_YAML)
DOCKER_COMPOSE_VERSION              1.14.0
NO_OPTION_COMMANDS                  pull stop restart
DOCKER_COMPOSE_NO_OPTION_COMMANDS   $(addprefix docker/,$(NO_OPTION_COMMANDS))
COMMAND                             ls -l
TARGET
```
