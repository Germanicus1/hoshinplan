var dummyVariableName = 1;
var isValidDate = function (value, userFormat) {
  var userFormat = userFormat || 'mm/dd/yyyy', // default format
  delimiter = /[^mdy]/.exec(userFormat)[0],
  theFormat = userFormat.split(delimiter),
  theDate = value.split(delimiter),

  isDate = function (date, format) {
    var m, d, y
    for (var i = 0, len = format.length; i < len; i++) {
      if (/m/.test(format[i])) m = date[i]
      if (/d/.test(format[i])) d = date[i]
      if (/y/.test(format[i])) y = date[i]
    }
    return (
      m > 0 && m < 13 &&
      y && y.length === 4 &&
      d > 0 && d <= (new Date(y, m, 0)).getDate()
    )
  }

  return isDate(theDate, theFormat)

}

var validateDate = function(formElem) {
	var inputs = $(formElem).find(".bootstrap-datepicker");
	for (var i=0; i<inputs.length; i++) {
		var inp = $(inputs[i]);
		var format = inp.attr("data-date-format");
		var value = inp.val();
		if (!isValidDate(value, format)) {
			alert("Not a valid date, the format should be: " + format);
			return false;
		}
	}
	return true;
}

var dateFormat = function(format, d) {
	if (typeof d === "undefined") { // partial
        return function (d) {
              return dateFormat.apply(this, [format, d]);
        };
    }
	if (d instanceof Array) {
		var date = new Date(d[0],d[1]-1,d[2]);
	} else {
		var date = new Date(d);
	}

	var ret = $.datepicker.formatDate(format, date);
	return ret;
}


function updateTimer(percent) {
	$("#health").popover('destroy');
	$("#health-popover").html("");
	$('#health').popover({
	    container: '#health-popover',
	    html: true,
	    placement: 'bottom',
	    title: function () {
		    var close = '<button type="button" class="close" data-dismiss="modal" aria-hidden="true" onclick="$(\'#health\').popover(\'hide\');$.undim();">&times;</button>';
		    return $(this).data("title") + close;
	    },
	    content: function () {
	        return $(this).next().html();
	    }
	});
	$( "#health" ).click(function( event ) {
	  event.stopPropagation();
	  $("#health-popover .popover").addClass("fixed-x");
	});
	$("#tutorial").hjq_tutorial("update");
	$('body').on('keyup.dismiss.healthPopover', function (e) {
		e.which == 27 && $('#health').popover('hide');
	});
	$('body').on('click.dismiss.healthPopover', function (e) {
		if ($('#health-popover div.popover:visible').length){
			$('#health').popover('hide');
		}
	});
}

function updateColors() {
	$('.kb-color').each(function () {
		var col = $(this).css('background-color');
		var colId = $(this).data('color-id');
		$(".kb-color-" + colId).css('background',col);
	});
}
$(document).ready(updateColors);

function fixedHorizontal() {
	if ($("html.pdf").length > 0) { return; }
        $("body.fixed-headers .navbar, body.fixed-headers .content-header, .fixed-x").map(function() {
		$(this).css({"margin-left": "0"}); 
		$(this).css({"width": "auto"});
		$(this).css({"width": $(this).width()});
		$(this).css({"margin-left": $(window).scrollLeft()}); 
	});
}


$(window).scroll(function () {
	if (typeof presenting != "undefined" && presenting) return;
        fixedHorizontal();
}); 

var eh = false;

var equalHeightSections = function() {
	if (typeof presenting != "undefined" && presenting) return;
	if (eh) return;
	eh = true;
	fixedHorizontal();
	equalHeights("div.objectives-wrapper");
	equalHeights("div.indicators-wrapper");
	equalHeights("div.tasks-wrapper");
	equalHeights("div.kb-lane");
	eh = false;
}
$(window).resize(equalHeightSections);
$(document).ready(equalHeightSections);
$(window).load(equalHeightSections);

var equalHeights = function(elements) {
	$(elements).height("auto");
	if (window.matchMedia('(max-width: 640px)').matches) return;
	var maxHeight = 0;
	//$(elements).css({border: "1px solid red"});
	$(elements).each(function(){
        	//$("body").append("Hola: " + $(this).parent().attr("id") + " . " + $(this).innerHeight() + "<br/>");
    		if ($(this).height() > maxHeight) {
	 	       maxHeight = $(this).height();
		}
	});
	$(elements).height(maxHeight);
	//$(elements).height("auto");
	//$("body").append("MH: " + maxHeight + "<br/>");
	
}

$(document).ready(function() {
	var tz = $(document).get_timezone();
	var domain = document.location.hostname.replace(/[^\.]*\./,'');
	document.cookie = "tz=" + tz+";domain="+domain+"; path=/";
});

Morris.Line.prototype.drawLinePath = function(path, lineColor, lineIndex) {
  return this.raphael.path(path).attr('stroke', lineColor).attr('stroke-width', this.lineWidthForSeries(lineIndex)).attr('stroke-dasharray', this.dashArrayForSeries(lineIndex));
};

Morris.Line.prototype.dashArrayForSeries = function(index) {
  if (this.options.dashArrays instanceof Array) {
    return this.options.dashArrays[index % this.options.dashArrays.length];
  } else {
    if (!this.options.dashArrays) this.options.dashArrays = "";
    return this.options.dashArrays;
  }
};