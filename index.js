const obj = document.querySelector("#current");

fetch("06f22.svg")
  .then(res => res.text())
  .then(svgText => {
    document.getElementById("kanji-container").innerHTML = svgText;
  });