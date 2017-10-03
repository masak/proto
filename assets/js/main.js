$(function(){
    setup_tags();
    setup_code_highlights();
});

function setup_code_highlights() {
    $('.code-mirror').each(function(i,el){
        var $el = $(el);
        var mirror = CodeMirror(el, {
            lineNumbers:    true,
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
