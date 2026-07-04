# Troubleshooting

## 1. Apache 500 Internal Server Error

확인:

```bash
sudo tail -n 80 /var/log/apache2/error.log
```

자주 발생한 원인:

- `require_once` 경로 오류
- `config/db.php` 누락
- PHP 문법 오류
- DB 접속 실패

## 2. PHP 문법 오류

```bash
php -l /var/www/html/index.php
```

`unexpected end of file`은 보통 `{}`, `if/endif`, `foreach/endforeach`가 닫히지 않았을 때 발생합니다.

## 3. Cloud DB 접속 실패

### Access denied

```text
ERROR 1045 (28000): Access denied for user
```

확인:

- DB 사용자명
- 비밀번호 대소문자
- DB User Host(IP)
- DB 권한 READ/CRUD/DDL

### Host not allowed

```text
Host '10.10.2.6' is not allowed to connect to this MySQL server
```

해결:

Cloud DB User 관리에서 Auto Scaling 서버가 위치한 subnet 대역을 허용합니다.

```text
10.10.2.%
```

## 4. Load Balancer Target DOWN

확인:

```bash
curl http://localhost/health.php
curl -I http://localhost/
sudo systemctl status apache2 --no-pager
```

ACG 확인:

- Load Balancer -> Web: TCP 80 허용
- Web 서버 Apache 실행 중
- `/var/www/html/health.php` 존재

## 5. Object Storage 이미지 미표시

확인:

```sql
SELECT id, title, image_url FROM posts ORDER BY id DESC LIMIT 5;
```

`image_url`이 `NULL`이면 업로드 실패입니다.

확인할 항목:

- NCP Access Key / Secret Key
- Bucket 이름
- Endpoint
- PHP AWS SDK 설치 여부
- 업로드 성공 후 DB INSERT/UPDATE에 image_url 포함 여부
