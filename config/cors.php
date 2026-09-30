<?php

return [

    /*
    | CORS hanya berlaku untuk endpoint API. Origin yang diizinkan adalah
    | alamat aplikasi Vue: dev server (5173) dan vite preview (4173).
    | Alamat lain dapat ditambahkan lewat FRONTEND_URL di file .env.
    */

    'paths' => ['api/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        env('FRONTEND_URL', 'http://localhost:5173'),
        'http://127.0.0.1:5173',
        'http://localhost:4173',
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
