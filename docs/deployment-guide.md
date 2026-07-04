# 배포 및 검증 가이드

## 1. 웹 서버 패키지 설치

```bash
sudo apt-get update
sudo apt-get install -y apache2 mysql-client php libapache2-mod-php php-mysql php-curl php-xml unzip composer
sudo systemctl enable apache2
sudo systemctl start apache2
```

## 2. 웹 루트

```text
/var/www/html
```

예상 파일 구조:

```text
/var/www/html
├── index.php
├── festivals.php
├── festival_detail.php
├── posts.php
├── post_create.php
├── post_detail.php
├── mypage.php
├── login.php
├── health.php
├── css/
│   └── style.css
└── config/
    ├── db.php
    ├── auth.php
    ├── nav.php
    ├── api.php
    ├── storage.php
    └── upload_image.php
```

## 3. Health Check 파일

```php
<?php
header('Content-Type: text/plain; charset=utf-8');
echo 'OK from ' . gethostname() . PHP_EOL;
```

저장 위치:

```bash
/var/www/html/health.php
```

## 4. DB 연결 확인

```bash
nc -vz <cloud-db-private-domain> 3306
php -r 'require "/var/www/html/config/db.php"; echo "PDO OK\n";'
```

## 5. PHP 문법 확인

```bash
php -l /var/www/html/index.php
php -l /var/www/html/festivals.php
php -l /var/www/html/festival_detail.php
php -l /var/www/html/posts.php
php -l /var/www/html/post_create.php
php -l /var/www/html/post_detail.php
php -l /var/www/html/mypage.php
```

## 6. Load Balancer 확인

```bash
curl -I http://<public-lb-domain>/
curl http://<public-lb-domain>/health.php
```

여러 번 요청했을 때 `web-01`, `web-02`, Auto Scaling 서버의 hostname이 번갈아 나오면 Load Balancing이 동작하는 것입니다.

## 7. 부하 테스트

```bash
sudo apt-get install -y apache2-utils
ab -n 1000 -c 50 http://<public-lb-domain>/
```

확인 항목:

- Failed requests
- Requests per second
- Time per request
- Auto Scaling 정책 실행 여부
- Target Group UP 상태

## 8. web-01에서 web-02로 소스 동기화

```bash
cd /var/www
sudo tar -czf /tmp/html-web01.tar.gz html
```

web-02에서:

```bash
sudo mv /root/html-web01.tar.gz /tmp/html-web01.tar.gz
sudo tar -xzf /tmp/html-web01.tar.gz -C /var/www
sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart apache2
```

운영 환경에서는 수동 복사 대신 GitHub 기반 배포 스크립트 또는 CI/CD를 사용하는 것이 좋습니다.
