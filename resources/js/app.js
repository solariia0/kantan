import './bootstrap';


let modal = document.getElementById('modal');

function showModal(card) {
    if (card.nodeName !== 'DIV') {
        card = card.parentElement;
    }
    let kanji_elem = card.children.item(0);
    let kanji_literal = kanji_elem.textContent;
    console.log(kanji_literal);
    // edit modal content
    modal.style.display = 'inline';
    // fetch the kanji with id
}

document.body.addEventListener('click', (event) => {
        if (event.target.matches('.card-item')) {
            showModal(event.target);
        }
    });
