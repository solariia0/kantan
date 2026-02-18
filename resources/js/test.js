import * as wanakana from 'wanakana';

let response = await fetch('/dict/kanjidic2-all-3.6.1.json');
let kanjidic = await response.json();
function buildKanjiMap(kanjidic) {
    return new Map(
        kanjidic.characters.map(c => [c.literal, c])
    );
}
kanjidic = buildKanjiMap(kanjidic);


response = await fetch('/dict/kradfile-3.6.1.json');
let kradfile = await response.json();

// test variables
let testPhase = 0; // 0 = radicals, 1 = single kanji, 2 = compound kanji
let tempRads = []; // temporary radical list
let tempKan = [];
let level = 4; // fetch this
let current = '';
let ans = ''; // idk if there is a better way to do this
let usrRadicals

// html
let hidden = document.querySelectorAll(".hidden");
let h1 = document.querySelector('h1');
let subhead = document.querySelector('h3');

// converts kanji to hex to fetch svg file
function kanjiToHex(kanji) {
    var kcode = kanji.codePointAt(0);
    var hex = kcode.toString(16);
    var zeros = 5 - hex.length;
    hex = "0".repeat(zeros) + hex;
    return hex;
}
function highlightRadicals(svgDoc, paths, radicalsToHighlight) {
    paths.forEach((path, index) => {
        // Extract the Kanji character (assuming each path corresponds to a stroke)
        // This step depends on the structure of the SVG and may require some tweaking based on the SVG data
        const pathData = path.getAttribute("d");

        // Here, we check if any of the radicals in the array appear in the path data
        // This is a basic check, so it assumes radicals have a simple visual representation in path data
        radicalsToHighlight.forEach(radical => {
            // Compare the radical with the path data (this part depends on how KanjiVG stores stroke data)
            if (pathData && pathData.includes(radical)) {
                // If the radical is found in the path data, highlight it
                path.setAttribute("stroke", "red");
                path.setAttribute("stroke-width", "2");
                path.setAttribute("fill", "none");  // Optionally remove the fill color for better highlighting
            }
        });
    });
}

// initiates the test
radical()

//// main test logic
const nextBttn = document.querySelector('#next');
const submitBttn = document.querySelector('#submit');

nextBttn.addEventListener('click', ()=>{
    subhead.style.color = 'black';
    if (testPhase < 2){
        // implement multi choice
        radical();
    } else if (testPhase < 4) {
        singleKanji();
    } else if (testPhase <= 6) {
        let kanji = getCompound(tempKan) // if temp kan don't match query usr_kanji table
    }
});

function radical() {
    let radicals = getRadicals(level);
    let current = radicals[Math.floor(Math.random()*(radicals.length))];
    console.log(current)

    let kanji = kanjiToHex(current);
    const obj = document.querySelector("#current");
    obj.setAttribute('data', `/kanji-svg/${kanji}.svg`);
    h1.style.display = 'none';
    h1.textContent = current;

    // randomly choose which quiz type
    toOnyomiInput(current)

    tempRads.push(current)
}

async function singleKanji(usrRads) {
    //const jlpt = getJlpt(level);
    //const kanjiList = jlpt.filter(char => tempRads.includes(char));
    let kanjiList = [];

    // incase a radical that's frequently used is called, narrow down by stroke order
    for (let kanji in kradfile.kanji) {
        const radicals = kradfile.kanji[kanji]; // this is an array of radicals
        for (let rad of tempRads) {
                    if (radicals.includes(rad)) {
                    kanjiList.push(kanji);
                    break; // stop after first matc
            }
        }
    }


    console.log(kanjiList);
    if (kanjiList.length > 2) {
        // fetch usrRads
        //let response = await fetch('/usr_radical/count');
        //let count = response.json();
        //console.log(count);
        //radical();
    }
    let current = kanjiList[Math.floor(Math.random()*(kanjiList.length))];
    console.log(current)

    let kanjiHex = kanjiToHex(current);
    const obj = document.querySelector("#current");

    fetch(`/kanji-svg/${kanjiHex}.svg`, { method: 'HEAD' })
        .then(response => {
            if (response.ok) {
                obj.setAttribute('data', `/kanji-svg/${kanjiHex}.svg`);
            } else {
                console.warn(`${kanjiHex}.svg does not exist`);
                let text = document.querySelector('h1');
                text.style.display = 'inline';
                text.textContent = current;
                obj.style.display = 'none';
            }
        })
        .catch(err => {
            console.error('Error checking file:', err);
        });

    // randomly choose which quiz type
    toOnyomiInput(current)

    tempKan.push(current)
}

function toOnyomiInput(current) {

    let kanjiData = showKanjiData(current);

    // selects a reading
    if (kanjiData.on.length > 1) {
        let readingIndex = Math.floor(Math.random()*2);
        let altReadings = [...kanjiData.on];
        ans = kanjiData.on[readingIndex];
        altReadings.splice(readingIndex, 1); // remove element at index r_i
        subhead.textContent = `What is the On'yomi reading of this radical?\nMeaning: ${kanjiData.meaning}
    \nNot these alternate readings ${altReadings.join(', ')}`;
    } else {
        subhead.textContent = `What is the On'yomi reading of this radical?\nMeaning: ${kanjiData.meaning}`;
        ans = kanjiData.on[0];
    }
}

submitBttn.addEventListener('click', ()=>{
    const usrAns = document.querySelector('input').value;
    const currentKanj = document.querySelector('h1').textContent;
    checkAns(ans, usrAns, currentKanj);

    if (testPhase === 7) {
        testPhase = 0;
    } else {
        testPhase++;
    }
})

async function checkAns(ans, usrAns, current) {
    const user = wanakana.toKatakana(usrAns).trim();
    const correct = String(ans).trim();
    if (user === correct) {
        // add to usr_radical table
        subhead.textContent = 'Correct';
    } else {
        subhead.textContent = `${correct}`;
        subhead.style.color = 'red';
    }
    console.log('hi')
    let hira = wanakana.toHiragana(correct);
    let data = await fetch(`/kanji-id/${encodeURIComponent(current)}/${encodeURIComponent(hira)}`);
    console.log(data);
    let data2 = await data.json();
    console.log(data2)
    try {
        const response = await fetch('/add-kanji', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            },
            body: JSON.stringify(data2)
        });

        const result = await response.json();
        console.log(result);
        alert(result.message);
    } catch (error) {
        console.error('Error:', error);
    }
}

// kanji filtering
function getJlpt(level) {
    return Array.from(kanjidic.values())
        .filter(chara => chara.misc?.jlptLevel === level)
        .map(chara => chara.literal);
}

function getRadicals(level) {
    const radicalSet = new Set(Object.values(kradfile.kanji).flat());

    return Array.from(kanjidic.values())
        .filter(chara => chara.misc?.jlptLevel === level)
        .map(chara => chara.literal)
        .filter(kanji => radicalSet.has(kanji));
}

function showKanjiData(kanji) {
    const chara = kanjidic.get(kanji);
    if (!chara) return null;

    const group = chara.readingMeaning?.groups?.[0];
    if (!group) return null;

    const data = { on: [], kun: [], meaning: [] };

    for (const reading of group.readings || []) {
        if (reading.type === 'ja_on') data.on.push(reading.value);
        else if (reading.type === 'ja_kun') data.kun.push(reading.value);
    }

    data.meaning = (group.meanings || [])
        .filter(m => m.lang === 'en')
        .map(m => m.value);

    return data;
}
