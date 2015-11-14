$(function(){
    setup_table();
});

function setup_table() {
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

    $('#dists_wrapper').addClass('table-responsive').unwrap();
    $('#search').remove();

    var filter_container = $('#dists_filter');
    var filter = filter_container.addClass('form-group').find('[type=search]')
        .addClass('form-control').attr('placeholder', 'Search');
    filter_container.append(filter);
    filter_container.find('label').remove();

    filter.focus();
}
