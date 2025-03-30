<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\ProjectController;
use App\Models\Project;



Route::get('/', function () {
    return <<<EOD
    Method uri                info
    GET    /api               this help page
    GET    /api/projects      id of all projects
    GET    /api/project/{id}  info from a project
    EOD;
});

Route::get('/projects', [ProjectController::class, 'index']);
Route::get('/project/{id}', [ProjectController::class, 'show']);
