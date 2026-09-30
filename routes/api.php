<?php

use App\Http\Controllers\Api\TaskApiController;
use Illuminate\Support\Facades\Route;

// Otomatis berprefiks /api  →  GET /api/tasks
Route::get('/tasks', [TaskApiController::class, 'index']);
