# syntax=docker/dockerfile:1

FROM php:8.3-cli-alpine

# Paket sistem yang dibutuhkan untuk MEMBANGUN ekstensi PHP di bawah,
# plus git & unzip yang dipakai Composer saat mengunduh paket.
RUN apk add --no-cache \
        git \
        unzip \
        curl-dev \
        sqlite \
        sqlite-dev \
        libzip-dev \
        oniguruma-dev \
    && docker-php-ext-install pdo pdo_sqlite mbstring bcmath zip curl \
    && rm -rf /var/cache/apk/*

# Salin biner Composer resmi (bukan diunduh manual lewat curl | php,
# supaya versinya konsisten dan tidak tergantung koneksi saat build).
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ── Layer yang JARANG berubah ditaruh di atas ───────────
# Hanya menyalin daftar dependensi dulu. Selama composer.json dan
# composer.lock tidak berubah, Docker memakai layer ini dari cache 
COPY composer.json composer.lock ./
RUN composer install \
        --no-dev \
        --no-scripts \
        --no-autoloader \
        --prefer-dist \
        --no-interaction

# ── Layer yang SERING berubah ditaruh di bawah ──────────
# Kode aplikasi baru disalin di sini. Mengubah satu baris kode TIDAK
# membatalkan cache composer install di atas.
COPY . .

# Lengkapi autoload (butuh file app/ yang baru saja disalin), siapkan
# folder yang wajib bisa ditulis Laravel, dan siapkan database SQLite
# bawaan supaya container bisa langsung dipakai tanpa langkah manual.
RUN composer dump-autoload --optimize --no-dev \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache database \
    && touch database/database.sqlite \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 8000

# Dijalankan setiap CONTAINER NYALA (beda dengan RUN yang dijalankan
# saat image dibangun): siapkan .env dan APP_KEY bila belum ada, jalankan
# migration, bangun cache config, lalu nyalakan server bawaan Laravel.
CMD sh -c " \
    [ -f .env ] || cp .env.example .env; \
    php artisan key:generate --force; \
    php artisan migrate --force; \
    php artisan config:cache; \
    php artisan serve --host=0.0.0.0 --port=8000 \
    "
