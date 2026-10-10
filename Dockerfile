# syntax=docker/dockerfile:1

# 8.3          : seri PHP yang dipakai project (Laravel 13 butuh >= 8.3)
# alpine3.22   : versi Alpine dikunci, varian alpine = image kecil
# Mau lebih ketat sampai nomor patch? Lihat langkah 3 di langkah_p6.md.
ARG PHP_TAG=8.3-cli-alpine3.22

# ════════════════════════════════════════════════════════════
# TAHAP 1 — build
# Boleh besar: ada git, unzip, dan Composer. Tahap ini HANYA
# dipakai untuk menghasilkan folder aplikasi yang sudah lengkap
# (vendor/ terpasang). Tahap ini tidak ikut ke image akhir.
# ════════════════════════════════════════════════════════════
FROM php:${PHP_TAG} AS build

# Paket apk sengaja tidak dikunci per-versi: Alpine menghapus versi lama dari
# repositorinya sehingga build bisa tiba-tiba gagal. Dasarnya sudah dikunci lewat
# tag Alpine, dan tahap ini tidak ikut ke image akhir.
# hadolint ignore=DL3018
RUN apk add --no-cache git unzip

# Biner Composer dari image resminya, versinya dikunci (bukan tag mengambang).
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Layer yang JARANG berubah di atas: daftar dependensi disalin dan
# dipasang SEBELUM kode aplikasi, supaya cache composer install awet.
COPY composer.json composer.lock ./
RUN composer install \
        --no-dev \
        --no-scripts \
        --no-autoloader \
        --prefer-dist \
        --no-interaction

# Layer yang SERING berubah di bawah.
COPY . .

RUN composer dump-autoload --optimize --no-dev \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache database \
    && touch database/database.sqlite

# ════════════════════════════════════════════════════════════
# TAHAP 2 — runtime
# Hanya yang dibutuhkan aplikasi saat melayani: PHP + kode +
# vendor/. Tidak ada git, unzip, Composer, maupun cache build.
# ════════════════════════════════════════════════════════════
FROM php:${PHP_TAG} AS runtime

# Pengguna biasa (bukan root). UID 1000 sudah umum dipakai.
RUN addgroup -g 1000 app \
    && adduser -D -u 1000 -G app app \
    && mkdir -p /var/www/html \
    && chown app:app /var/www/html

WORKDIR /var/www/html

# --chown membuat berkas langsung dimiliki "app" saat disalin, jadi
# tidak perlu "RUN chown -R" yang menggandakan ukuran layer.
COPY --from=build --chown=app:app /app /var/www/html

USER app

EXPOSE 8000

# Container dinyatakan sehat bila endpoint /up (bawaan Laravel) menjawab
# 200. wget bawaan Alpine (busybox) dipakai agar tidak perlu memasang apa pun.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8000/up || exit 1

# Bentuk JSON + exec: PHP menjadi proses utama (PID 1) sehingga
# menerima sinyal stop dari Docker dengan benar.
CMD ["sh", "-c", "[ -f .env ] || cp .env.example .env; php artisan key:generate --force && php artisan migrate --force && php artisan config:cache && exec php artisan serve --host=0.0.0.0 --port=8000"]
