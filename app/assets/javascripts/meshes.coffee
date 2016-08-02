# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# Only run in Meshes index page
return unless $('#new_mesh').length && $('#meshes_table').length

#
# Dropzone
#

# Disable autodiscover for all elements
Dropzone.autoDiscover = false

# Create a dropzone for uploading new meshes
new Dropzone '#new_mesh',
  # url: $('#new_mesh').data('url')
  paramName: 'mesh[upload]'
  thumbnailWidth: 80
  thumbnailHeight: 80
  parallelUploads: 1
  previewTemplate: $('#mesh_dropzone_template').html()
  autoQueue: false    # make sure files aren't queued until manually added
  previewsContainer: '#previews'  # container to display the previews
  clickable: '.fileinput-button'  # element used as click-trigger to select files
  init: ->
    _this = @ # closure
    # Hook up the start button
    @on 'addedfile', (file) ->
      $(file.previewElement).find('.start').click () ->
        _this.enqueueFile(file)
    # Update the total progress bar
    @on 'totaluploadprogress', (progress) ->
      $('#total-progress .progress-bar').css('width', progress + '%')
    # Show progress bar when upload starts & disable start button
    @on 'sending', (file) ->
      $('#total-progress').css('opacity', '1')
      $(file.previewElement).find('.start').prop('disabled', true)
    # Hide total progress bar when nothing's uploaded anymore
    @on 'queuecomplete', (progress) ->
      $('#total-progress').css('opacity', '0')
    # Remove file when it is finished uploading
    @on 'success', (file, response) ->
      @removeFile file
      rowNode = meshTable.row.add(response.mesh).draw().node()
      $(rowNode).hide().fadeIn('slow')
      noty
        text: 'Mesh was successfully created.'
        type: 'success'
        theme: 'relax'
        timeout: 2000
    # Handle upload errors
    @on 'error', (file, response) ->
      errors = response.errors
      msg = """
      #{(msg for msg in errors).join('<br/>')}
      """
      $(file.previewElement).find('.dz-error-message').html msg
    # Setup buttons for all transfers
    $('#actions .start').click ->
      _this.enqueueFiles _this.getFilesWithStatus(Dropzone.ADDED)
    $('#actions .cancel').click ->
      _this.removeAllFiles true
    # Don't submit this form
    $('#new_mesh').submit(false)

#
# Datatables
#

# Set up datatable
meshTable = $('#meshes_table').DataTable
  pageLength: 50
  order: [[ 4, 'desc' ]]
  columns: [
    {
      orderable: false
      searchable: false
      data: (row, type, val, meta) ->
        if type == 'display'
          """
            <a class="btn btn-default" href="#{row.meta.sessions.link}">
              <i class="fa fa-folder-open-o"></i> Open Sessions...
            </a>
           """
        else
          row.meta.sessions.link
    }
    {
      title: 'File Name'
      # type == set, display, filter, sort
      data: (row, type, val, meta) ->
        if type == 'display'
          """<a href="#{row.upload.link}" download>#{row.upload.name}</a>"""
        else
          row.upload.name
    }
    {
      title: 'Sessions'
      data: 'meta.sessions.count'
    }
    {
      title: 'File Size'
      data: (row, type, val, meta) ->
        if type == 'display'
          numeral(row.upload.size).format('0 b')
        else
          row.upload.size
    }
    {
      title: 'Created'
      data: (row, type, val, meta) ->
        if type == 'display' || type == 'filter'
          moment(row.created_at).format('lll')
        else
          row.created_at
    }
    {
      orderable: false
      searchable: false
      data: (row, type, val, meta) ->
        if type == 'display'
          """
            <a class="btn btn-danger pull-right delete-mesh" href="#{row.link}" title="Delete #{row.upload.name}" data-remote="true" data-method="delete" data-confirm="Are you sure you want to delete this mesh? This will delete <strong>ALL</strong> sessions for this mesh and is <strong>irreversible</strong>!" rel="nofollow">
              <i class="fa fa-trash-o"></i> Delete
            </a>
          """
        else
          row.link
    }
  ]

#
# Rails unobtrusive Javascript
#

# Mesh delete button
$(document).on {
  'confirm:complete': (e, answer) ->
    if answer
      $(@).attr 'disabled', 'disabled'
  'ajax:success': (e, data, status, xhr) ->
    meshTable.row( $(@).parents('tr') ).remove().draw()
    noty
      text: 'Mesh and all of its sessions were successfully deleted.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Mesh failed to be deleted: #{error}<br />
        <ul id="errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '.delete-mesh'
