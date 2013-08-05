// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.noConflict();

jQuery.ajaxSetup({
    'beforeSend': function (xhr) {
        xhr.setRequestHeader("Accept", "text/javascript")
    }
});

function remove_fields(link) {
    $(link).previous("input[type=hidden]").value = "1";
    $(link).up(".fields").hide();
}

function add_fields(link, association, content) {
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g")
    $(link).up().insert({
        before: content.replace(regexp, new_id)
    });
}

jQuery.fn.submitWithAjax = function () {
    this.unbind('submit', false);
    this.submit(function () {
        jQuery.post(this.action, jQuery(this).serialize(), null, "script");
        return false;
    })

    return this;
};

//This will "ajaxify" the links
function ajaxLinks() {
    jQuery('.ajaxForm').submitWithAjax();
}

var $ = jQuery;

$(document).ready(function () {

    // All non-GET requests will add the authenticity token
    // if not already present in the data packet
    $(document).ajaxSend(function (event, request, settings) {
        if (typeof(window.AUTH_TOKEN) == "undefined") return;
        // <acronym title="Internet Explorer 6">IE6</acronym> fix for http://dev.jquery.com/ticket/3155
        if (settings.type == 'GET' || settings.type == 'get') return;
        settings.data = settings.data || "";
        settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(window.AUTH_TOKEN);
    });
    ajaxLinks();

    //Best In Place Gem Init
    $('.best_in_place').best_in_place();

    //jQuery UI Sortable and Mixonic Ranked-Model to sort and submit playlist orders
    var item_id,
        position,
        url;

    $(".sort-list").sortable({
        axis: 'y',
        containment: 'parent',
        cursor: 'crosshair',
        items: 'tr.sortable',

        stop: function(e, ui) {
            ui.item.children('td').effect('highlight', {}, 1000);
        },
        update: function(e, ui) {
            item_id = ui.item.attr('data-id');
            position = ui.item.index();
            url = $(this).attr('data-url');
            console.log(item_id + " " + position + " " + url);
            $.ajax({
                type: 'POST',
                url: $(this).data('url'),
                dataType: 'json',

                //the :thing hash gets passed to @thing.attributes
                data: {
                    id: item_id,
                    position_position: position
                }
            });
        }
    });

    $(".album-sort-list").sortable({
        axis: 'y',
        containment: 'parent',
        cursor: 'crosshair',
        items: 'tr.sortable',

        stop: function(e, ui) {
            ui.item.children('td').effect('highlight', {}, 1000);
        },
        update: function(e, ui) {
            item_id = ui.item.attr('data-id');
            position = ui.item.index();
            url = $(this).attr('data-url');
            console.log(item_id + " " + position + " " + url);
            $.ajax({
                type: 'POST',
                url: $(this).data('url'),
                dataType: 'json',

                //the :thing hash gets passed to @thing.attributes
                data: {
                    id: item_id,
                    track_num_position: position
                }
            });
        }
    });

    //Auto-completing sections of the movies form based on selected inputs
    $('#movie_movie_type_id').on("change", function() {
        $('#movie_language_tracks_input').find('input').prop('checked', false);
        var movieType = $(this).val();

        /*
        14 Arabic Movie
        3 Cantonese Movie
        19 Danish Movie
        15 Dutch Movie
        17 Finnish Movie
        2 French Movie
        7 German Movie
        21 Hebrew Movie
        12 Hindi Movie
        1 Hollywood Movie
        9 Italian Movie
        5 Japanese Movie
        4 Korean Movie
        23 Malay Movie
        6 Mandarin Movie
        18 Norwegian Movie
        20 Persian Movie
        16 Portuguese Movie
        10 Russian Movie
        8 Spanish Movie
        13 Swedish Movie
        22 Thai Movie
        */

        switch(movieType) {
            case "1" :
                $('#movie_foreign_language_title').val("");
                $('#movie_foreign_language_title').prop('disabled', true);
                $('#movie_language_tracks_eng').prop('checked', true);
                break;
            case "3" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_zho').prop('checked', true);
                break;
            case "14" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_ara').prop('checked', true);
                break;
            case "19" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_dan').prop('checked', true);
                break;
            case "15" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_ndl').prop('checked', true);
                break;
            case "17" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_fin').prop('checked', true);
                break;
            case "2" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_fra').prop('checked', true);
                break;
            case "7" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_deu').prop('checked', true);
                break;
            case "21" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_heb').prop('checked', true);
                break;
            case "12" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_hin').prop('checked', true);
                break;
            case "9" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_ita').prop('checked', true);
                break;
            case "5" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_jpn').prop('checked', true);
                break;
            case "4" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_kor').prop('checked', true);
                break;
            case "23" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_msa').prop('checked', true);
                break;
            case "6" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_zho').prop('checked', true);
                break;
            case "18" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_nor').prop('checked', true);
                break;
            case "20" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_fas').prop('checked', true);
                break;
            case "16" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_por').prop('checked', true);
                break;
            case "10" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_ru').prop('checked', true);
                break;
            case "8" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_spa').prop('checked', true);
                break;
            case "13" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_swe').prop('checked', true);
                break;
            case "22" :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_tha').prop('checked', true);
                break;
            default :
                $('#movie_foreign_language_title').prop('disabled', false);
                $('#movie_language_tracks_eng').prop('checked', false);
                break;
        }
    });

    $('#movie_screener_remarks_other').on("change", function() {
        if($(this).prop('checked')) {
            $('#movie_screener_remarks_other_input').find('input').prop('disabled', false);
        } else {
            $('#movie_screener_remarks_other_input').find('input').prop('disabled', true);
        }
    });

    $('#movie_airline_rights').on("change", function() {
        var airlineRights = $(this).val();
        switch(airlineRights) {
            case "North America" :
                $('#movie_airline_countries').prop('disabled', true);
                break;
            case "Worldwide" :
                $('#movie_airline_countries').prop('disabled', true);
                break;
            default :
                $('#movie_airline_countries').prop('disabled', false);
                break;
        }
    });

    // Remote pagination links for UI Dialog forms
    $('body').on('click', '.ui-dialog .pagination a', function () {
        $.rails.handleRemote($(this));
        return false;
    });

    // Show and hide "working" spinner
    $(".spinner-trigger[data-remote='true']")
        .on("ajax:beforeSend",  function() {
            $('#spinner').removeClass('transparent');
            console.log("on");
        })
        .on("ajax:ajaxComplete", function() {
            $('#spinner').addClass('transparent');
            console.log("off");
        })
    
    $('input[type="file"]').attr("size", 6);

    //enable chosen js
    $('.select2').select2();


});
