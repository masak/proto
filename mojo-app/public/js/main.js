$(function(){
    setup_table();
});

function setup_table() {
    var el = $('#dists'), filter_container, filter, table_plugin, sort_order;

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
    sort_order = window.location.hash.match(/sort-([^-]+)-([^-])+/);
    if ( sort_order ) {
        table_plugin.order([
            sort_order[1], sort_order[2] == 'a' ? 'asc' : 'desc'
        ]).draw();
    }
    el.find('th').click(function(){
        window.location.hash = 'sort-' + $(this).index() + '-'
            + $(this).attr('aria-sort').substr(0,1);
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
