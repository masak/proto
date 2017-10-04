$(function(){
    setup_tags();
    setup_code_highlights();
    setup_gen_search_info();

    $(document).ready(function(){
        $('[data-toggle="tooltip"]').tooltip();
    });
});

function setup_gen_search_info() {
    var el = $('#dist-list,#core-dist-list');
    if (! el.length) return;
    el.find('[class^="glyphicon-"]').addClass('glyphicon');
    el.find('h2 i').each(function() {
        $(this).addClass('icon-24-' + $(this).attr('title'))
        .attr('title', 'Hosted on: ' + $(this).attr('title'))
        .attr('data-toggle', 'tooltip');
    });
    el.find('.glyphicon-star').parent('li')
        .attr('title', 'Number of likes').attr('data-toggle', 'tooltip');
    el.find('.glyphicon-info-sign').parent('li')
        .attr('title', 'Number of open Issues').attr('data-toggle', 'tooltip')
        .attr('class', 'issues');
    el.find('.travis').each(function() {
        $(this).attr('title', 'Travis status: ' + $(this).attr('title'))
        .attr('data-toggle', 'tooltip');
    });
    el.find('.appveyor').each(function() {
        $(this).attr('title', 'Appveyor status: ' + $(this).attr('title'))
        .attr('data-toggle', 'tooltip');
    });
    el.find('.glyphicon-wrench').parent('li')
        .attr('title', 'Last updated on').attr('data-toggle', 'tooltip');
    el.find('.btn-group a').addClass('btn btn-xs btn-default');
    el.find('ul,.btn-group').css({visibility: 'visible'});
}

function setup_code_highlights() {
    $('.code-mirror').each(function(i,el){
        var $el = $(el);
        var mirror = CodeMirror(el, {
            lineNumbers:    $el.attr('data-no-line-numbers') ? 0 : 1,
            lineWrapping:   true,
            mode:           $el.attr('data-highlight-type'),
            viewportMargin: Infinity,
            readOnly:       true,
            value:          $el.find('.file-content').text().trim(),
            viewportMargin: Infinity
        });
        $el.find('.file-content').remove();
    });

    $('.CodeMirror-linenumber').each(function(i, el){
        var el_id = 'L' + $(el).text();
        $(el).wrap('<a href="#' + el_id + '"></a>')
            .css({cursor: 'pointer'}).attr('id', el_id);
    });
}

function setup_tags() {
    $('#weak-tag-expander').click(function() {
        $('.weak-tag').removeClass('hidden');
        $(this).remove();
        return false;
    });
}
