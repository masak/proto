$(function(){
    setup_tags();
});

function setup_tags() {
    $('#weak-tag-expander').click(function() {
        $('.weak-tag').removeClass('hidden');
        $(this).remove();
        return false;
    });
}
