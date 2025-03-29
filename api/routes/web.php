<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return <<<EOD
    Endpoints:
    GET /api : this help page
    GET /api/all : list of all projects
    GET /api/info?id=... : info from a project
    EOD;
});

Route::get('/all', function () {
    return "Not implemented yet";
});

Route::get('/info', function () {
    return "Not implemented yet";
});
