var table_plugin;

$(function(){
    setup_table();
    setup_search_query_save();
    setup_search_box_defocus();
});

function setup_search_box_defocus() {
    /* Focus search box on page load, but remove focus if the user appears
        to be trying to scroll the page with keyboard, rather than typing
        a search query
    */
    $('#dists_filter input').focus().keydown( function(e){
        var el = $(this);
        if ( e.which == 32 && el.val().length                ) { return true; }
        if ( e.which == 32 || e.which == 34 || e.which == 40 ) { el.blur()  ; }
        // key codes: 32: space; 34: pagedown; 40: down arrow
    });
}


function setup_table() {
    var el = $('#dists'), filter_container, filter, sort_order;

    table_plugin = el.DataTable({
        paging: false,
        autoWidth: false,
        scrollX: false,
        info: false,
        columnDefs: [
            {
                targets: [ 2, 3, 4, 5, 6 ],
                searchable: false
            },
            {
                targets: [ 6 ],
                orderSequence: [ "desc", "asc" ]
            }
        ]
    });

    // This lets us restore correct sort order if the user uses "Back"
    // button in their browser
    if ( hash_store('sort-col') ) {
        table_plugin.order([
            hash_store('sort-col'),
            hash_store('sort-dir') == 'a' ? 'asc' : 'desc'
        ]).draw();
    }
    el.find('th').click(function(){
        hash_store('sort-col', $(this).index()                      );
        hash_store('sort-dir', $(this).attr('aria-sort').substr(0,1));
    });

    // Mess around with markup to accomodate the table plugin and marry
    // it nicely with both our JS-less version of the site and Bootstrap
    $('#dists_wrapper').addClass('table-responsive').unwrap();
    $('#search').remove();
    filter_container = $('#dists_filter');
    filter = filter_container.addClass('form-group').find('[type=search]')
        .addClass('form-control').attr('placeholder', 'Search');
    filter_container.append(filter);
    filter_container.find('label').remove();
    filter.focus();
}

function setup_search_query_save() {
    var el = $('#dists_filter').find('[type=search]'),
        q  = hash_store('q');

    if ( typeof(q) !== 'undefined' ) {
        el.val( q );
        table_plugin.search( q ).draw();
    }
    el.change(function(){
        hash_store('q', $(this).val())
    });
}

function hash_store (key, value){
    var obj;

    try       { obj = jQuery.deparam(window.location.hash.replace(/^#/,'')) }
    catch (e) { obj = {} }

    if ( typeof(value) !== 'undefined' ) {
        obj[key] = value;
        window.location.hash = jQuery.param( obj, true );
    }

    return obj[key];
}