$(function(){
    setup_table();
});

function setup_table() {
    var filter_container, filter;

    $('#dists').DataTable({
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
