jQuery(function ($) {
    var module_list = new List('module_list', {
        valueNames: [ 'name', 'description' ],
        page: 9e9
    });
    setup_search_box(module_list);
    $('.tablesorter').find('th').append('<i/>');
    $('.tablesorter').tablesorter({
        sortList: [[0,0]],
        headers: {
            0: { sorter: 'text'},
            2: { sorter: false },
            3: { sorter: 'text' }
        }
    });
});

function setup_search_box(module_list) {
    var el = $('#my_search_box .search');
    if ( ! el.length ) { return; }

    // Here we have logic for handling cases where user views a repo
    // and then presses "Back" to go back to the list. We want to
    //     (a) NOT scroll to search input if scroll position is offset.
    //          This is a "Back" after scrolling and viewing a repo
    //     (b) Refresh 'search' if search input has some text.
    //          This is a "Back" after clicking on search results
    if ( $(window).scrollTop() == 0 ) {
        el.focus();
    }

    if ( el.val().length ) {
        module_list.search(el.val());
    }
}
