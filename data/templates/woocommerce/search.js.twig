var form        = document.querySelector('.phpdocumentor-search'),
    searchField = document.querySelector('.phpdocumentor-search input[type="search"');

// Init autoComplete.
var autoCompletejs = new autoComplete({
    data: {
        src: searchIndex,
        key: ['name'],
        cache: true
    },
    placeHolder: 'Search',
    selector: '#autoComplete',
    highlight: true,
    threshold: 1,
    searchEngine: 'strict',
    maxResults: 100,
    resultsList: {
        render: true,
        container: function(source) {
            source.classList.add('phpdocumentor-search-results__entries');
        },
        destination: document.querySelector('.phpdocumentor-search-results'),
        position: 'afterend',
        element: 'ul'
    },
    resultItem: {
        content: function(data, source) {
            source.classList.add('phpdocumentor-search-results__entry');
            var name  = 'name' === data.key ? data.match : data.value.name,
                fqsen = 'fqsen' === data.key ? data.match : data.value.fqsen;

            source.innerHTML += '<a href="' + data.value.url + '">' + name + "</a>\n";
            if (fqsen){
                source.innerHTML += '<small>' + fqsen + "</small>\n";
            }
            source.innerHTML += '<span class="phpdocumentor-summary">' + data.value.summary + '</span>';
        },
        element: 'li'
    },
    noResults: function() {
        var result = document.createElement('li');
        result.setAttribute('class', 'no-result');
        result.setAttribute('tabindex', '1');
        result.innerHTML = 'No results were found. Please try a different search term.';
        document.querySelector('#autoComplete_list').appendChild(result);
    }
});

// Display search field.
form.classList.add('phpdocumentor-search--enabled');
form.classList.add('phpdocumentor-search--active');
searchField.setAttribute('placeholder', 'Search');
searchField.removeAttribute('disabled');

// Close search results with ESC.
window.addEventListener('keyup', function(event) {
    if (event.code === 'Escape') {
        document
            .querySelector('.phpdocumentor-search-results__entries')
            .innerHTML = '';

        searchField.value = '';
    }
});
