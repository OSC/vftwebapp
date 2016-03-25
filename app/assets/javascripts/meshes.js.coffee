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

  # Change delete button icon to a spinner when user clicks confirm button
  $(document).on {
    'confirm:complete': (e, answer) ->
      if answer
        $(this).addClass('disabled')
        $(this).find('i').attr('class', 'fa fa-spinner fa-spin')
  }, '.destroy-model'

  # Change button icons to a spinner when user clicks button & disable link
  $(document).on {
    'click': ->
      $link = $(this).clone()
      $link.attr 'href', '#'
      $link.removeAttr 'id'
      $link.addClass('disabled')
      $icon = $link.find('i')
      if $icon.length == 1
        $icon.attr 'class', 'fa fa-spinner fa-spin'
      else
        $link.prepend $('<span><i class="fa fa-spinner fa-spin" /> </span>')
      $(this).parent().append $link
      $(this).hide()
    'ajax:complete': ->
      $(this).parent().find('a.disabled').remove()
      $(this).show()
  }, '.remote-spinner'

  # Destroy all Paraview popovers if user clicks anywhere
  $(document).on 'click', ->
    $('.paraview-popover').popover 'destroy'

  # Set default resolution for VNC sessions
  $('#indexTable').on {
    'ajax:before': ->
      href = $(this).attr 'href'
      resx = window.screen.width * 0.8
      resy = window.screen.height * 0.8
      $(this).attr 'href', href + "?resx=" + parseInt(resx) + "&resy=" + parseInt(resy)
  }, '.launch-vftsolid,.paraview-popover'

  # Control job submission behavior
  $('#indexTable').on {
    'click': ->
      # make a spinner while we wait for job submission
      icon = $('<span class="spinner"><i class="fa fa-spinner fa-spin" /> </span>')
      $(@).prepend icon
      $(@).addClass('disabled')
  }, '.launch-btn'
