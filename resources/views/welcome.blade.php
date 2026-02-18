<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Document</title>
    @vite('resources/css/app.css')
    @vite('resources/js/test.js')
</head>
<body>
    <main>
        <object id="current" type="image/svg+xml"></object>
        <h1></h1>
        <h3></h3>

        <div id="multi-choice" class="hidden">
            <button id="option-1">value</button>
            <button id="option-2">value</button>
            <button id="option-3">value</button>
            <button id="option-4">value</button>
        </div>

        <div id="text-input" >
            <input
                type="text"
            />
        </div>
        <button id="next">next</button>
        <button id="submit">></button>

    </main>

    <x-nav></x-nav>

</body>
</html>
