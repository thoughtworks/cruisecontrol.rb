// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

document.observe("dom:loaded", function() {
  $$("#projects .buttons .build_button").invoke("observe", "click", function(evt) {
    evt.stop();
    var button = evt.findElement();
    
    if (button.readAttribute("disabled") !== "disabled") {
      button.disabled = true;
      button.className = 'build_button_disabled';
      
      var oldText = button.innerHTML;
      button.setAttribute("disabled", "disabled");

      button.up("form.build_project").request({ evalJS: true, method: 'post' });
    }
  });
  
  $$("#project_build_now .build_button").invoke("observe", "click", function(evt) {
    evt.stop();
    var button = evt.findElement();
    button.setAttribute("disabled", "disabled");
    button.up("form.build_project").submit();
  });
  
  $$("#projects").each(function(projects) {
    var path = projects.readAttribute("data-refresh-path"),
        interval = projects.readAttribute("data-refresh-interval");
    
    setInterval(function() { new Ajax.Updater('', path, { method: 'get', evalScripts: true }); }, interval);    
  });
  
  $$("#build_details .section_header").invoke("observe", "click", function(evt) {
    evt.stop();
    var section = evt.findElement().parentNode;
    
    if (section.hasClassName("section_open")) {
      section.removeClassName("section_open").addClassName("section_closed");
    } else {
      section.addClassName("section_open").removeClassName("section_closed");
    }
  });

  $$("button[href]").invoke("observe", "click", function(evt) {
    evt.stop();
    var button = evt.findElement();
    window.location = button.readAttribute("href");
  });
});