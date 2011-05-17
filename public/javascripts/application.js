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

  $("#build_details .section_header").live("click", function(e) {
    e.preventDefault();
    $(this).parent().toggleClass("closed");
  });

  $("button[href]").live("click", function(e) {
    e.preventDefault();
    window.location = $(this).attr("href");
  });

  $("#build").live("change", function() {
    window.location = $(this).val();
  });
});