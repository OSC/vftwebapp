# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

root = exports ? this

# Default dropzone options for mesh file uploads
root.dropzoneMeshOpts =
  paramName: 'mesh[upload_attributes][file]'
  maxFiles: 1
  dictDefaultMessage: 'Drop your mesh here to upload'
  previewTemplate: '
    <div class="file-row">
      <div>
        <p>
        <span class="name" data-dz-name></span>
        <span class="size pull-right" data-dz-size></span>
        </p>
        <strong class="error text-danger" data-dz-errormessage></strong>
      </div>
      <div>
        <div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
          <div class="progress-bar progress-bar-success" style="width:0%;" data-dz-uploadprogress></div>
        </div>
        <button data-dz-remove class="btn btn-warning cancel">
            <i class="glyphicon glyphicon-ban-circle"></i>
            <span>Cancel</span>
        </button>
      </div>
    </div>
  '
  success: (file, response) ->
    $.getScript($(file.previewElement).parent().attr('action') + '.js')

# Disable auto discover for all elements
Dropzone.autoDiscover = false

jQuery ->
  # Set up datatables
  root.indexTable = $('#indexTable').DataTable()

  # Initialize best_in_place
  $('.best_in_place').best_in_place()

  # Initialize dropzones with options
  $('.dropzone').dropzone dropzoneMeshOpts

  # best_in_place event handling
  $('.dataTable').on {
    'ajax:success': ->
      # Update datatable after inplace field change
      row = $(this).closest('tr')
      indexTable.row(row).invalidate()
    'ajax:error': (e, error) ->
      # Throw up alert error if something goes wrong
      data = $.parseJSON error.responseText
      alert 'Name ' + data.name
  }, '.best_in_place'

  # Don't let users click multiple times the 'Add Mesh' link
  $('#new_mesh,#new_session').on {
    'ajax:beforeSend': ->
      text = $(this).html()
      $placeholder = $('<a href="#" id="new_model_placeholder">').html(text)
      $placeholder.find('i').attr('class', 'fa fa-spinner fa-spin')
      $(this).parent().append($placeholder)
      $(this).hide()
    'ajax:success': ->
      $('#new_model_placeholder').remove()
      $(this).show()
  }

  # Change delete button icon to a spinner when user clicks confirm button
  $(document).on 'confirm:complete', '.destroy-model', (e, answer) ->
    $(this).find('i').attr('class', 'fa fa-spinner fa-spin') if answer

  # Control behavior of Paraview popover
  $(document).on {
    'hidden.bs.popover': (e) ->
      # destroy the popover if hidden (one time use anyways)
      $(@).popover 'destroy'
    'click': (e) ->
      # make a spinner while we wait for popover to load
      icon = $('<span class="spinner"><i class="fa fa-spinner fa-spin" /> </span>')
      $(@).prepend icon
  }, '.paraview-popover'
