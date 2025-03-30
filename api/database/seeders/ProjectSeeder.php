<?php

namespace Database\Seeders;

use Illuminate\Support\Facades\DB;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class ProjectSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('projects')->insert([
            'name' => 'Portfolio',
            'description' => <<<EOD
            This website is a portfolio of my work,
            It uses the flake feature of nix to be deployed declarativly
            The frontend uses svelte
            The backend uses Laravel and postgresql
            EOD,
        ]);
    }
}
