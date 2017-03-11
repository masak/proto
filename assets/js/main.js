var table_plugin;

$(function(){
    setup_tags();
    setup_table();
    setup_search_query_save();
    setup_search_box_defocus();
});

function setup_tags() {
    var limit_count = 3, added_weak_tag_expander = 0;
    $('#tags').html(
        $('#tags li').sort(function(el){
            return $(el).find('small').text() < limit_count ? 1 : 0;
        }).sort(function(el){
            // our < limit_count tags are in reverse-alphabetic order now
            // sort them again to reverse the order
            return $(el).find('small').text() < limit_count ? 1 : 0;
        })
    );

    $('#tags li').each(function (i, el) {
        if($(el).find('small').text() < limit_count) {
            if ( ! added_weak_tag_expander ) {
                $(el).before(
                    '<li id="weak-tag-expander"><a class="btn btn-xs'
                    + ' btn-default" href="#">VIEW ALL TAGS</a></li>'
                );
                $('#weak-tag-expander').click(function() {
                    $('.weak-tag').removeClass('hidden');
                    $(this).remove();
                    return false;
                });
                added_weak_tag_expander = 1;
            }
            $(el).addClass('weak-tag hidden');
        }
    });

    $('#tags').removeClass('hidden');
}

function setup_search_box_defocus() {
    /* Focus search box on page load, but remove focus if the user appears
        to be trying to scroll the page with keyboard, rather than typing
        a search query
    */

    var search = $('#dists_filter input');
    if( typeof window.orientation === 'undefined' && ! search.val().length
        && $(window).scrollTop() == 0 ) {
        search.focus().keydown( function(e){
            var el = $(this);
            if ( e.which == 32 && el.val().length ) { return true; }
            if (e.which == 32 || e.which == 34 || e.which == 40) { el.blur(); }
            // key codes: 32: space; 34: pagedown; 40: down arrow
        });
    }
}


function setup_table() {
    var el = $('#dists'), filter_container, filter, sort_order;

    // Custom sorter for dates to sort N/A dates as oldest
    $.fn.dataTable.ext.order['custom-na-date'] = function ( settings, col ) {
        return this.api().column( col, {order:'index'} ).nodes().map(
            function (td, i) {
                var text = $(td).text();
                return text == 'N/A' ? '0000-00-00' : text;
            });
    };

    // it appears to need this in order to sort the name column right
    $.fn.dataTable.ext.order['text-only'] = function ( settings, col ) {
        return this.api().column( col, {order:'index'} ).nodes().map(
            function (td, i) {
                return $(td).text();
            });
    };

    table_plugin = el.DataTable({
        paging: false,
        autoWidth: false,
        scrollX: false,
        info: false,
        columnDefs: [
            {
                targets: [ 0 ],
                orderDataType: "text-only",
                type: "perlModule"
            },
            {
                targets: [ 1 ],
                searchable: true
            },
            {
                targets: [ 2, 3, 4, 5 ],
                searchable: false
            },
            {
                targets: [ 5 ],
                orderSequence: [ "desc", "asc" ],
                orderDataType: "custom-na-date"
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
