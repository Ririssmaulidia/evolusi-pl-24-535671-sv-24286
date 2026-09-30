<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Task;
use Illuminate\Http\JsonResponse;

class TaskApiController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(
            Task::query()->orderBy('due_date')->get()
        );
    }
}
