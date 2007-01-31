// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function mark_for_edit_and_focus(to_mark, to_focus) {
  to_mark.className = 'edit';
  to_focus.focus();
}

function show_tab(name) {
  page_name = "tab_page_" + name
  label_name = "tab_item_" + name
  
  pages = document.getElementsByClassName("tab_page");
  for (i = 0; i < pages.length; i++) {
    pages[i].className = "tab_page" + (pages[i].id == page_name ? " selected" : "")
  }

  labels = document.getElementsByClassName("tab_item");
  for (i = 0; i < labels.length; i++) {
    labels[i].className = "tab_item" + (labels[i].id == label_name ? " selected" : "")
  }
}
