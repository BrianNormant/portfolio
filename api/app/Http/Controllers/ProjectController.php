<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Models\Project;

class ProjectController extends Controller
{
    /**
     * Display a listing of the resource.
     * @return JsonResponse
     */
    public function index(): JsonResponse
    {
        $ids = Project::all()->pluck('id');
        return response()->json($ids);
    }

    /**
     * Store a newly created resource in storage.
     * @return void
     */
    public function store(Request $request): void
    {

    }

    /**
     * Display the specified resource.
     * @return JsonResponse
     */
    public function show(string $id): JsonResponse
    {
        $project = Project::where($id)->first();
        if ($project) {
            return response()->json($project);
        } else {
            return response()->json([
                'message' => 'This Project id doesn\'t exist',
                'id' => $id],
            404);
        }
    }

    /**
     * Update the specified resource in storage.
     * @return void
     */
    public function update(Request $request, string $id): void
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     * @return void
     */
    public function destroy(string $id): void
    {
        //
    }
}
