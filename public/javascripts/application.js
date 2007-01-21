// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function mark_for_edit_and_focus(to_mark, to_focus) {
  to_mark.className = 'edit';
  to_focus.focus();
}