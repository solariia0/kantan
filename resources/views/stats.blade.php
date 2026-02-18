<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Document</title>
    @vite('resources/css/app.css')
    @vite('resources/js/app.js')
</head>
<body>
<main>
    <input
        type="text"
        />

    <div id="filters">
        <div class="badge">N5</div>
        <div class="badge">N4</div>
        <div class="badge">N3</div>
        <div class="badge">N2</div>
        <div class="badge">N1</div>
        <div class="badge">Known</div>
        <div class="badge">Unknown</div>
    </div>

    <section id="cards">
    @foreach($db as $character)
        @if($character['learnt'])
            <div class="stat-card card-item">
                <h1 class="card-item">{{ $character['literal'] }}</h1>
                <p class="card-item">mastery:</p>
                <progress value="{{ $character['proficiency'] }}" max="10" class="card-item"></progress>

            </div>
        @else
        <div class="stat-card off card-item">
            <h1 class="card-item">{{ $character['literal'] }}</h1>
        </div>
        @endif
    @endforeach
    </section>

    <div id="modal" class="stat-card">
        <h1>Kanji</h1>
        <progress></progress>
        <h5>Commonly mistaken for:</h5>
        <h5>mistake1, mistake2</h5>
        <p>On'yomi: hira</p>
        <p>Kun'yomi: hira</p>
        <p>Meaning: eng</p>
    </div>


</main>

<x-nav></x-nav>

</body>
</html>
