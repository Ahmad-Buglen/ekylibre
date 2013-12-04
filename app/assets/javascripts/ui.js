/* -*- mode: javascript; indent-tabs-mode: nil; -*- */

(function ($) {
    "use strict";

    // Toggle now with
    $(document).ready(function (event) {
        $('*[data-toggle-now-with]').each(function () {
            var element = $(this);
            element.hide();
            $(element.attr('data-toggle-now-with')).show();
        });
    });


    // Auto-reconnection with time-out
    $.timedSession = {
        timer: null,
        reconnectable: true,
        openReconnection: function () {
            var body = $('body');
            var url = body.attr('data-timeout-href');
            if ($.timedSession.reconnectable && url !== null && url !== undefined) {
                window.clearTimeout($.timedSession.timer);
                $.timedSession.reconnectable = false;
                // Formize.Dialog.open(url, null, 0);
                $.ajaxDialog(url, {
                    width: 0,
                    height: 0,
                    returns: {
                        granted: function (frame, data, textStatus, request) {
                            frame.dialog("option", "effect", "fadeOut");
                            frame.dialog("close");
                            $.timedSession.reconnectable = true;
                            $.timedSession.startCountdown();
                        },
                        denied: function (frame, data, textStatus, request) {
                            frame.html(request.responseText);
                            frame.dialog("widget").effect("shake", {}, 100, function () {
                                frame.find('input[type="password"]').focus();
                            });
                        }
                    }
                });
                // Adds $.timedSession.reconnectable = true if granted and not denied
            }
        },
        startCountdown: function () {
            var body = $('body');
            var timeout = body.attr('data-timeout');
            window.clearTimeout($.timedSession.timer);
            if (!isNaN(timeout) && $.timedSession.reconnectable) {
                var duration = parseFloat(timeout)*1000;
                $.timedSession.timer = window.setTimeout($.timedSession.openReconnection, duration);
            }
        }
    };
    $(document).ready($.timedSession.startCountdown);
    $(document).ajaxStop($.timedSession.startCountdown);

    // Set auto resizing
    /*$.resizeLayout = function () {
        $.layoutResizing.resize($('#body.resizable'), $(window).width(), $(window).height());
        $("input[type='text']:first").select();
        $("input[type='text']:first").focus();
    };
    $.resizeLayoutProperly = function () {
        $.resizeLayout();
        window.setTimeout($.resizeLayout, 300);
    };
    $(document).ready($.resizeLayoutProperly);
    $(window).resize($.resizeLayoutProperly);
    $(window).bind("layout:change", $.resizeLayoutProperly);
	*/


    $.fn.raiseContentErrorToFieldSet = function () {
        var fss = $(this);
        fss.each(function () {
            var fs = $(this);
            if (fs.find('.error').length > 0) {
                fs.parents('.fieldset').addClass('error');
            }
        });
    };
    $(document).on('page:load', '.fieldset .fieldset-fields', $.fn.raiseContentErrorToFieldSet);
    $(document).ready(function () {
        $(".fieldset .fieldset-fields").raiseContentErrorToFieldSet();
    });



    // Update DOM with new system
    $(document).behave("ajax:success", "*[data-update]", function (event, data, status, xhr) {
        var element = $(this);
        var position = $.trim(element.data("update-at")).toLowerCase();
        if (position === "top") {
            $(element.data("update")).prepend(data);
        } else if (position === "bottom") {
            $(element.data("update")).append(data);
        } else if (position === "before") {
            $(element.data("update")).before(data);
        } else if (position === "after") {
            $(element.data("update")).after(data);
        } else {
            $(element.data("update")).html(data);
        }
    });

    // Redirect to the given location
    $(document).behave("ajax:success", "*[data-redirect]", function (event, data, status, xhr) {
        var element = $(this);
        window.location.replace(data);
    });

    // Alert on errors
    $(document).behave("ajax:error", "*[data-update], *[data-redirect]", function (request, status, error) {
        alert("AJAX " + status + ": " + error);
    });


    $(document).behave("change keyup", "select[data-redirect]", function () {
        var element = $(this), params = {};
        params[element.attr("name") || element.attr("id") || "undefined"] = element.val();
        window.location.replace($.buildURL(element.data("redirect"), params));
    });

    $(document).on("change keyup", "select[data-use-redirect]", function () {
        var element = $(this), params = {}, url;
        url = element.find(":selected").data('redirect');
        if (url !== null && url !== undefined) {
            window.location.replace(url);
        }
    });

    $.fn.showValueElements = function () {
        var element = $(this), prefix = element.data("show-value");
        element.find("option").each(function () {
            $(prefix + $(this).val()).hide();
        });
        $(prefix + element.val()).show();
    }

    $(document).on("change keypress", "select[data-show-value]", $.fn.showValueElements);
    $(document).ready(function () {
        $("select[data-show-value]").showValueElements();
    });



    // Old system adaptation to jQuery
    $(document).behave("click", "a[data-new-item]", function () {
        var element = $(this), list_id, list;
        list_id = '#'+element.data('new-item');
        list = $(list_id);
        if (list[0] === undefined || list[0] === null) {
            alert("Cannot find element " + list_id);
        } else {
            $.ajaxDialog(element.attr('href'), {
                returns: {
                    success: function (frame, data, status, request) {
                        var record_id = request.getResponseHeader("X-Saved-Record-Id"), combo_box, parameter, parameters, refresh_url;
                        // Reload selector with new record as default selection
                        // alert(list);
                        $.EkylibreSelector.set(list, record_id);
                        // // Updates manually fields like before
                        // combo_box = $('input[data-value-container="' + list.attr("id") + '"]');
                        // if (combo_box[0] !== undefined) {
                        //   $.ajax(combo_box.data('combo-box'), {
                        //     data: {id: record_id},
                        //     success: function (data, status, request) {
                        //       $.setComboBox(combo_box, $.parseJSON(request.responseText)[0]);
                        //     }
                        //   });
                        // } else if (refresh_url !== null && refresh_url !== undefined) { // Select case
                        //   parameter = list.data('id-parameter-name') || "selected";
                        //   parameters = {};
                        //   parameters[parameter] = record_id;
                        //   alert(refresh_url);
                        //   $.ajax(refresh_url, {
                        //     data: parameters,
                        //     success: function (data, status, request) {
                        //       list.html(request.responseText);
                        //       $(list_id).trigger("emulated:change");
                        //     }
                        //   });
                        // } else {
                        //   alert("Unrefreshable selector type");
                        // }
                        frame.dialog("close");
                    },
                    invalid: function (frame, data, textStatus, request) {
                        frame.html(request.responseText);
                    }
                }
            });
        }
        return false;
    });

    // Use element to compute a calculation
    $(document).behave("click", "*[data-close-dialog]", function () {
        var element = $(this), frame;
        frame = $('#'+element.data("close-dialog"));
        frame.dialog("close");
        return false;
    });



    // Use element to compute a calculation
    $(document).behave("load", "*[data-use]", function () {
        var element = $(this);
        if (element.isCalculationResult()) {
            element.attr("data-auto-calculate", "true");
        } else {
            element.removeAttr("data-auto-calculate");
        }
    });

    $.calculateResults = function () {
        $("*[data-use][data-auto-calculate]").each($.calculate);
    };

    $.calculateResults();
    window.setInterval($.calculateResults, 300);


    $(document).behave("load", "*[data-balance]", function () {
        var element = $(this), operands = $(this).data("balance").split(/\s\-\s/g).slice(0,2);
        $(document).behave('change emulated:change', operands.join(", "), function () {
            var plus = $(operands[0]).sum(), minus = $(operands[1]).sum();
            // alert(operands[0] + " > " + plus);
            // alert(operands[1] + " > " + minus);
            if (plus > minus) {
                element.numericalValue(plus - minus);
            } else {
                element.numericalValue(0);
            }
        });
    });

    $(document).behave("load keyup change emulated:change", "*[data-less-than-or-equal-to]", function () {
        var element = $(this), maximum = parseFloat(element.data("less-than-or-equal-to"));
        if (element.numericalValue() > maximum) {
            //element.numericalValue(maximum);
            element.removeClass("valid");
            element.addClass("invalid");
        } else {
            element.removeClass("invalid");
            element.addClass("valid");
        }
    });

    $(document).behave("load", "*[data-valid-if-equality-between]", function () {
        var element  = $(this);
        var selector = element.data("valid-if-equality-between");
        $(document).behave("load keyup change emulated:change remove", selector, function () {
            var value = null, equality = true;
            $(selector).each(function () {
                if (value === null) { value = $(this).numericalValue(); }
                if (value !== $(this).numericalValue()) { equality = false; }
            });
            element.toggleClass("valid", equality);
            element.toggleClass("invalid", !equality);
        });
    });

    // Removes DOM Element defined by the selector
    $(document).behave("click", "a[data-remove]", function () {
        $($(this).data("remove")).deepRemove();
        return false;
    });

    // Adds parameters
    $(document).behave("ajax:before confirm", "*[data-with]", function () {
        var element = $(this), params = $.unparam(element.data("params"));
        $(element.data("with")).each(function () {
            var paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id");
            if (paramName !== null && (typeof(paramName) !== "undefined")) {
                params[paramName] = $(this).val() || $(this).html();
            }
        });
        element.data("params", $.param(params));
        return true;
    });

    // Adds a HTML
    $(document).behave("focusout", "input[data-add-line-unless]", function () {
        var element = $(this);
        if (element.numericalValue() !== 0 && !$(element.data("add-line-unless")).hasClass("valid")) {
            if (element.data("with")) {
                var params = {};
                $(element.data("with")).each(function () {
                    var paramName = $(this).data("parameter-name") || $(this).attr("id");
                    if (paramName !== null && paramName !== undefined) {
                        params[paramName] = $(this).val() || $(this).html();
                    }
                });
                element.data("params", $.param(params));
            }
            $.rails.handleRemote(element);
        }
    });

    // Nullify inputs if it filled
    $(document).behave("keyup", "input[data-exclusive-nullify]", function () {
        var element = $(this);
        if (element.numericalValue() !== 0) {
            $(element.data("exclusive-nullify")).val('');
        }
    });

    $(document).behave("click", "*[data-click]", function () {
        $($(this).data("click")).each(function () {
            $(this).trigger("click");
        });
        return false;
    });

    $(document).behave("change", "input:checkbox[data-add-class-to]", function () {
        var element = $(this), classes = element.data("add-class") || element.attr("class");
        if (element.prop("checked")) {
            $(element.data("add-class-to")).addClass(classes);
        } else {
            $(element.data("add-class-to")).removeClass(classes);
        }
    });


    $(document).behave("click", "*[data-toggle-class]", function () {
        var element = $(this), classes = element.data("toggle-class"), classesArray = classes.split(/\s+/g), gotClasses=true;
        for (var i=0; i < classesArray.length; i += 1) {
            if (!element.hasClass(classesArray[i])) {
                gotClasses = false;
                break;
            }
        }
        if (gotClasses) {
            element.removeClass(classes);
        } else {
            element.addClass(classes);
        }
        return false;
    });

    $(document).on("click", "*[data-select-deck]", function () {
        var element = $(this), deck = element.data('select-deck'), container = $('div[data-deck]');
        // We need to use attr to make CSS working
        if (container.attr('data-deck') === deck) {
            deck = 'default';
        }
        container.attr('data-deck', deck);
        container.find('> div').hide();
        container.find('> #' + deck).show();
        $('a[data-select-deck]').removeClass('active');
        $('a[data-select-deck="' + deck + '"]').addClass('active');
        return false;
    });


    $(document).on("click", "a[data-toggle='dropdown']", function () {
        var element = $(this), menu = element.next();
        if (menu.is(':visible')) {
            menu.hide();
        } else {
            menu.show();
        }
        return false;
    });

    $(document).on("focusout blur", "a[data-toggle='dropdown']", function () {
        var element = $(this), menu = element.next();
        if (menu.is(':visible')) {
            window.setTimeout(function () {
                menu.hide();
            }, 300);
        }
        return true;
    });


    $(document).on("click", "a[data-toggle='side']", function () {
        var element = $(this), wrap = $('#wrap');
        if (wrap.hasClass('mini-screen-show-side')) {
            element.removeClass('active');
            wrap.removeClass('mini-screen-show-side');
        } else {
            element.addClass('active');
            wrap.addClass('mini-screen-show-side');
        }
        return false;
    });

    $(document).on("click", "a[data-toggle='help']", function () {
        var element = $(this), wrap = $('#wrap'), collapsed;
        if (wrap.hasClass('show-help')) {
            $('a[data-toggle="help"]').removeClass('active');
            wrap.removeClass('show-help');
            collapsed = 1;
        } else {
            $('a[data-toggle="help"]').addClass('active');
            wrap.addClass('show-help');
            collapsed = 0;
        }
        $.ajax(element.attr("href"), {
            data: { collapsed: collapsed },
            type: 'POST'
        });
        return false;
    });

    $(document).on("click", "a[data-toggle='kujaku']", function () {
        var element = $(this), wrap = element.closest('.kujaku'), collapsed;
        if (wrap.hasClass('collapsed')) {
            wrap.removeClass('collapsed');
            collapsed = 0;
        } else {
            wrap.addClass('collapsed');
            collapsed = 1;
        }
        $.ajax(element.attr("href"), {
            data: { collapsed: collapsed },
            type: 'POST'
        });
        return false;
    });


    $(document).on("click", "a[data-toggle='result']", function () {
        var element = $(this), content = element.closest('.result').find('.content'), collapsed;
        if (content.hasClass('collapsed')) {
            content.removeClass('collapsed');
        } else {
            content.addClass('collapsed');
        }
        return false;
    });


    // Toggle side menu
    $(document).behave("click", "a[data-toggle-view-mode]", function () {
        var element = $(this);
        element.attr("href");
        $.ajax(element.data("toggle-view-mode"), {
            success: function (data, status, xhr) {
                window.location.replace(element.attr("href"));
            }
        });
        return false;
    });


    // Toggle side menu
    $(document).behave("click", "a[data-toggle-module]", function () {
        var element = $(this), module = element.closest(".sd-module"), target = module.find(".sd-content"), shown;
        if (element.hasClass("show")) {
            element.removeClass("show");
            element.addClass("hide");
            module.removeClass("collapsed");
            target.slideDown();
            shown = 1;
        } else {
            element.removeClass("hide");
            element.addClass("show");
            module.addClass("collapsed");
            target.slideUp();
            shown = 0;
        }
        $.ajax(element.attr("href"), {data: {module: element.data("toggle-module"), shown: shown }});
        return false;
    });


    // Toggle side menu
    $(document).on("click", "a[data-toggle-snippet]", function () {
        var element = $(this), snippet = element.closest(".snippet"), target = snippet.find(".snippet-content"), collapsed;
        if (snippet.hasClass("collapsed")) {
            snippet.removeClass("collapsed");
            target.slideDown();
            collapsed = 0;
        } else {
            snippet.addClass("collapsed");
            target.slideUp();
            collapsed = 1;
        }
        $.ajax(element.attr("href"), {
            data: { collapsed: collapsed },
            type: 'POST'
        });
        return false;
    });


    // Live copy
    $(document).behave("keyup change emulated:change", "input[data-live-copy-to]", function () {
        var element = $(this);
        $(element.data("live-copy-to")).val(element.val());
    });


    // Auto focus
    $.autoFocus = function () {
        this.focus();
        // this.select();
    };
    // $.behave("*[data-autofocus]", "load", $.autoFocus);
    // $.behave("input[type='text']:first", "load", $.autoFocus);
    /*    $.behave("*:input:visible:first", "load", $.autoFocus);
          $.behave("*[data-autofocus]:visible", "load", $.autoFocus);*/


    // Toggle visibility
    $(document).on("click", "a[data-toggle-with]", function (event) {
        var element = $(this);
        if (element.is(":visible")) {
            element.hide();
            $(element.data('toggle-with')).show();
        } else {
            $(element.data('toggle-with')).hide()
            element.show();
        }
        return false;
    });


    // Toggle visibility
    $(document).on("click", "a[data-toggle-visibility]", function (event) {
        var selector = $(this).data('toggle-visibility');
        $(selector).each(function (index) {
            var target = $(this);
            if (target.is(":visible")) {
                target.hide();
            } else {
                target.show();
            }
        });
        return false;
    });


    $(document).on("click", "a[data-insert-into][data-insert]", function (event) {
        var element = $(this), data, target;
        data = element.data("insert");
        $(element.data("insert-into")).each(function (index) {
            insertInto(this, '', '', data);
        });
        return false;
    });

    $(document).on("click", "[data-toggle-set]", function (event) {
        var element = $(this), target = element.closest('.fieldset').find(element.data("toggle-set")), shown;
        if (element.hasClass("collapsed")) {
            element.removeClass("collapsed");
            element.addClass("not-collapsed");
            target.slideDown();
            shown = 1;
        } else {
            element.removeClass("not-collapsed");
            element.addClass("collapsed");
            target.slideUp();
            shown = 0;
        }
        return false;
    });

    $(document).on("mouseenter", ".btn", function (event) {
        var button = $(this), text;
        if (button.attr("title") == null || button.attr("title") == undefined) {
            text = button.find(".text:hidden").first();
            if (text !== null && text !== undefined) {
                button.attr("title", $.trim(text.html()));
            }
        }
        return true;
    });

    $(document).on("mouseenter", "a i", function (event) {
        var icon = $(this), link;
        link = icon.closest("a");
        if (link.attr("title") == null || link.attr("title") == undefined) {
            link.attr("title", $.trim(link.text()));
        }
        return true;
    });

    $(document).on("click", "a[data-target]", function (event) {
        var selector = $(this).data('target');
        $(selector).each(function (index) {
            var target = $(this);
            if (target.hasClass("visible")) {
                target.removeClass("visible");
            } else {
                target.addClass("visible");
            }
        });
        return false;
    });


    $(document).behave("load", "[data-show-if]", function (event) {
        var element = $(this), choices, potentials = "", key;
        choices = $.parseJSON(element.attr("data-show-if"));
        for (key in choices) {
            if (potentials.length > 0) {
                potentials += ", ";
            }
            potentials += choices[key];
        }
        element.behave("load click keyup change emulated:change", function (event) {
            var targets = choices[element.val()];
            $(potentials).hide();
            if (targets !== null && targets !== undefined) {
                $(targets).show();
            }
        });
    });

    $(document).behave("load", "[data-hide-if]", function (event) {
        var element = $(this), choices, potentials = "", key;
        choices = $.parseJSON(element.attr("data-hide-if"));
        for (key in choices) {
            if (potentials.length > 0) {
                potentials += ", ";
            }
            potentials += choices[key];
        }
        element.behave("load click keyup change emulated:change", function (event) {
            var targets = choices[element.val()];
            $(potentials).show();
            if (targets !== null && targets !== undefined) {
                $(targets).hide();
            }
        });
    });


    // Initializes date fields
    $(document).behave("focusin click keyup change", 'input[data-date]', function (event) {
        var element = $(this), locale, options = {}, name, hidden;
        if (element.prop("datepickerLoaded") !== "Yes!") {
            locale = element.data("date-locale");
            if ($.datepicker.regional[locale] === null || $.datepicker.regional[locale] === undefined) {
                locale = "en";
            }
            $.datepicker.setDefaults( $.datepicker.regional[locale] );
            name = element.attr("name");
            element.removeAttr("name");
            hidden = $("<input type='hidden' name='" + name + "'/>");
            hidden.val(element.data("date-iso"));
            element.before(hidden);

            options['dateFormat']  = element.data("date");
            options['altField']    = hidden;
            options['altFormat']   = 'yy-mm-dd';
            options['defaultDate'] = element.val();

            // Check for dependents
            if (hidden.data('dependents') !== undefined && hidden.data('dependents') !== null) {
                if (hidden.data('observe') === undefined || hidden.data('observe') === null) {
	            hidden.attr('data-observe', '1000');
                }
            }
            element.datepicker(options);
            element.prop("datepickerLoaded", "Yes!");
        }
    });



    // Initializes date fields
    $(document).on("focusin click keyup change", 'input[type="date"]', function (event) {
        var element = $(this), locale, options = {}, name, hidden;
        if (element.attr("autocomplete") !== "off") {
            locale = element.attr("lang");
            if ($.datepicker.regional[locale] === null || $.datepicker.regional[locale] === undefined) {
                locale = "en";
            }
            $.datepicker.setDefaults( $.datepicker.regional[locale] );
            name = element.attr("name");
            element.removeAttr("name");
            hidden = $("<input type='hidden' name='" + name + "'/>");
            hidden.val(element.val());
            element.before(hidden);

            options['dateFormat']  = element.data("format");
            options['altField']    = hidden;
            options['altFormat']   = 'yy-mm-dd';

            // Check for dependents
            if (hidden.data('dependents') !== undefined && hidden.data('dependents') !== null) {
                if (hidden.data('observe') === undefined || hidden.data('observe') === null) {
	            hidden.attr('data-observe', '1000');
                }
            }
            element.datepicker(options);
            element.datepicker("setDate", new Date(element.val()));
            element.attr("autocomplete", "off");
        }
    });

    // Initializes datetime fields
    $(document).on("focusin click keyup change", 'input[type="datetime"]', function (event) {
        var element = $(this), locale, options = {}, name, hidden;
        if (element.attr("autocomplete") !== "off") {
            locale = element.attr("lang");
            if ($.timepicker.regional[locale] === null || $.timepicker.regional[locale] === undefined) {
                locale = "en";
            }
            $.timepicker.setDefaults( $.timepicker.regional[locale] );
            name = element.attr("name");
            element.removeAttr("name");
            hidden = $("<input type='hidden' name='" + name + "'/>");
            hidden.val(element.val());
            element.before(hidden);
            element.val(element.data('human-value'));

            options['dateFormat']  = element.data("format");
            options['altFieldTimeOnly']  = false;
            options['altField']    = hidden;
            options['altFormat']   = 'yy-mm-dd';
            options['altTimeFormat'] = 'HH:mm';
            options['isRTL'] = !!($("html").attr("dir") === "rtl");
            options['stepMinute'] = 5;

            // Check for dependents
            if (hidden.data('dependents') !== undefined && hidden.data('dependents') !== null) {
                if (hidden.data('observe') === undefined || hidden.data('observe') === null) {
	            hidden.attr('data-observe', '1000');
                }
            }
            element.datetimepicker(options);
            element.attr("autocomplete", "off");
        }
    });





    $.initializeDateSelectors = function() {
        $('input[type="date"], input[type="datetime"]').trigger('change');
    };
    $(document).ready($.initializeDateSelectors);
    $(document).on("page:load cocoon:after-insert", $.initializeDateSelectors);




    $(document).on("click", "a[data-remove-closest]", function () {
        var element = $(this);
        element
            .closest(element.data('removeClosest'))
            .remove();
        return false;
    });


    /* Refresh behave items */
    // $(document).on("cocoon:after-insert", function (event) {
    //     $.Behave.refresh();
    // });

    // $(document).on("page:change", function (event) {
    //     $.Behave.refresh();
    // });



    $(document).ready(function () {
        $("input[type='checkbox'][data-show], input[type='checkbox'][data-hide], input[type='radio'][data-show], input[type='radio'][data-hide]").each($.toggleCheckboxes);
        $("select[data-auto-timezone]").val(jstz.determine().name());
    });


})( jQuery );
