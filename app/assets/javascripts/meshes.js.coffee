# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.dropzone_options =
  paramName: 'mesh[upload_attributes][file]'
  maxFiles: 1
  addRemoveLinks: true
  success: (file, response) ->
    $.getScript($(file.previewElement).parent().attr('action') + '.js')

jQuery ->
  $('.best_in_place').best_in_place()

  $('.best_in_place').bind 'ajax:success', ->
    row = $(this).closest('tr')
    meshTable.row(row).invalidate()

  $('#submit_new_mesh').click ->
    $('#new_mesh').submit()

  $('.dropzone').dropzone dropzone_options
