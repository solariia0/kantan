<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;


Route::get('/', function () {
    // if none are known redirect to learn page
    return view('welcome');
});

// revise page:
// pagination for words requiring revision
// add a query ot the url to pick random numbers

Route::get('/learn', function () {
    return view('learn');
});

// user page:
// pagination for entire db

Route::get('/stats', function () {
    $db = [
        [
            'id'=> 001,
            'literal'=>'地',
            'n_level'=>4,
            'learnt'=>true,
            'proficiency'=>7,
            'onyomi'=>'',
            'kunyomi'=>'',
            'mistakes'=>['ち', '土', '他']
        ],
        [
            'id'=> 002,
            'literal'=>'地',
            'n_level'=>4,
            'learnt'=>false, // have this fetch in js and add data-learnt='false'
            'proficiency'=>3,
            'onyomi'=>'',
            'kunyomi'=>'',
            'mistakes'=>['ち', '土', '他']
        ]
    ];
    return view('stats', ['db' => $db]);
});


Route::get('/usr_radical/count', function(){
    $hasMoreThanTwo = DB::table('your_table')
            ->limit(3)   // only need 3 rows
            ->count() > 2;

    return $hasMoreThanTwo;
});

Route::get('/compound', function(){
    $results = DB::table('usr_kanj as u1')
        ->join('usr_kanj as u2', function($join) {
            $join->whereRaw('u1.id != u2.id');
        })
        ->join('entr', 'entr.id', '=', 'u1.entrid')
        ->join('kanj', function($join) {
            $join->on('kanj.txt', '=', DB::raw("u1.txt || u2.txt")); // PostgreSQL string concatenation
        })
        ->whereRaw("LENGTH(u1.txt || u2.txt) = 2") // PostgreSQL LENGTH
        ->select([
            'entr.id',
            DB::raw('kanj.txt as compound_kanji'),
            'u1.reading as reading_kanji_1',
            'u2.reading as reading_kanji_2'
        ])
        ->get();

    return $results;
});

Route::get('/kanji-id/{kanji}/{reading}', function($kanji, $reading){
    $entry = DB::table('entr')
        ->join('kanj', 'kanj.entr', '=', 'entr.id')
        ->join('rdng', 'rdng.entr', '=', 'entr.id')
        ->where('kanj.txt', $kanji)
        ->where('rdng.txt', $reading)
        ->select('entr.id', 'kanj.txt', 'rdng.txt')
        ->first(); // Get a single record

    return response()->json($entry);
});

Route::post('/add-kanji', function(Request $request) {
    // Optional: validate incoming request
    $request->validate([
        'entrid'  => 'required|integer',
        'txt'     => 'required|string',
        'reading' => 'required|string',
    ]);

    // Insert into the database
    DB::table('usr_kanj')->insert([
        'entrid'  => $request->entrid,
        'txt'     => $request->txt,
        'reading' => $request->reading,
    ]);

    return response()->json([
        'message' => 'Kanji inserted successfully',
        'data' => $request->only('entrid', 'txt', 'reading')
    ]);
});
