<?php

namespace Tests\Feature;

use App\Models\Task;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TaskApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_tasks_returns_json_list(): void
    {
        Task::factory()->count(3)->create();

        $response = $this->getJson('/api/tasks');

        $response->assertOk()
            ->assertJsonCount(3)
            ->assertJsonStructure([
                ['id', 'title', 'description', 'category', 'due_date', 'is_done'],
            ]);
    }

    public function test_api_tasks_returns_empty_array_when_no_tasks(): void
    {
        $this->getJson('/api/tasks')
            ->assertOk()
            ->assertExactJson([]);
    }
}
