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
}

function setup_tags() {
    $('#weak-tag-expander').click(function() {
        $('.weak-tag').removeClass('hidden');
        $(this).remove();
        return false;
    });
}
