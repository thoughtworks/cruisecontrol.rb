// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function() {
  $("#projects .buttons .build_button").live("click", function(e) {
    e.preventDefault();
    var button = $(this);

    if (button.attr("disabled") !== "disabled") {
      button.attr("disabled", "disabled");
      
      var form = button.closest("form.build_project");

      $.post(form.attr("action"), form.serialize(), function(resp) {
        $("#projects").html(resp);
      });
    }
  });

  $("#project_build_now .build_button").live("click", function(e) {
    e.preventDefault();
    var button = $(this);
    button.attr("disabled", "disabled");
    button.closest("form.build_project").submit();
  });

  $("#projects").each(function() {
    var projects = $(this),
        path = projects.attr("data-refresh-path"),
        interval = projects.attr("data-refresh-interval");

    setInterval(function() {
      $.get(path, function(resp) { projects.html(resp); });
    }, interval);
  });

  var sectionNames = $("#build .build_details .build_nav .section_name");
  var sections = $("#build .build_details .sections");

  function selectTab(tabName) {
    sectionNames.filter(".active").removeClass("active");
    sectionNames.find("a[href$='" + tabName + "']").closest(".section_name").addClass("active");
    sections.find(".section.active").removeClass("active");
    sections.find("#" + tabName).addClass("active");
  }

  function currentTab() {
    return window.location.hash ? window.location.hash.substring(1) : null;
  }

  if (currentTab()) {
    selectTab(currentTab());
  }

  $(window).bind("hashchange", function(e) {
    selectTab(currentTab());
  });

  $("#build .build_details .section_name a").click(function(e) {
    e.preventDefault();
    e.stopPropagation();
    location.hash = $(this).attr("href");
    return false;
  });

  if ($("#build").length === 1) {
    var buildsList   = $("#build .left_column");
    var buildDetails = $("#build .sections");
    var newWidth = null;

    function adjustBuildWidth() {
      buildDetails.width(0);
      newWidth = $(window).width() - buildsList.width() - 40;
      buildDetails.width( newWidth );
    }

    $(window).resize(adjustBuildWidth);
    adjustBuildWidth();
  }

  $("button[href]").live("click", function(e) {
    e.preventDefault();
    window.location = $(this).attr("href");
  });

  $("#select_build").live("change", function(evt) {
    evt.preventDefault();
    window.location = $(this).val();
  });
});