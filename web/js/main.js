jQuery(function ($) {
    setup_search_box();
});

function setup_search_box() {
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
        userList.search(el.val());
    }
}
