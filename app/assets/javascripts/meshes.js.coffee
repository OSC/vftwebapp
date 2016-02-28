# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

root = exports ? this

# Default dropzone options for mesh file uploads
root.dropzoneOpts =
  paramName: 'mesh[upload_attributes][file]'
  maxFiles: 1
  addRemoveLinks: true
  success: (file, response) ->
    $.getScript($(file.previewElement).parent().attr('action') + '.js')

# Disable auto discover for all elements
Dropzone.autoDiscover = false

jQuery ->
  # Initialize best_in_place
  $('.best_in_place').best_in_place()

  # Update datatable after inplace field changed
  $('.best_in_place').bind 'ajax:success', ->
    row = $(this).closest('tr')
    meshTable.row(row).invalidate()

  # Use a link to submit a form
  $('#submit_new_mesh').click ->
    $('#new_mesh').submit()

  # Programmatically define dropzones with personal options
  $('.dropzone').dropzone dropzoneOpts
