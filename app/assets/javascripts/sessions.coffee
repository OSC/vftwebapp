# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


# Only run in Sessions index page
return unless $('#new_session').length && $('#sessions_table').length

#
# Datatables
#


# Set up datatable
sessTable = $('#sessions_table').DataTable
  pageLength: 50
  order: [[ 0, 'desc' ]]
  columns: [
    {
      title: 'Id'
      data: 'id'
    }
    {
      title: 'State'
      data: 'state'
    }
    {
      title: 'Stage'
      data: (row, type, val, meta) ->
        if type == 'display'
          """
            <div class="session-stage-#{row.stage.step}">
              <badge class="badge">#{row.stage.step}</badge> #{row.stage.name}
            </div>
          """
        else if type == 'sort'
          row.stage.step
        else
          row.stage.name
    }
    {
      title: 'Status'
      data: (row, type, val, meta) ->
        if type == 'display'
          if row.status.failed
            label = 'danger'
          else if row.status.complete
            label = 'success'
          else if row.status.not_submitted
            label = 'default'
          else
            label = 'primary'
          """
            <h4 class="session-status">
              <span class="status-label label label-#{label}">#{row.status.name}</span
            </h4>
           """
        else
          row.status
    }
    {
      orderable: false
      searchable: false
      className: 'workflow-column'
      data: (row, type, val, meta) ->
        if row.status.active
          'Active'
        else if row.status.not_submitted
          """
            <a class="btn btn-success submit-session" href="#{row.links.submit}" data-remote="true" data-method="patch" rel="nofollow">
              <i class="fa fa-play-circle"></i> Launch
            </a>
          """
        else if row.status.failed
          """
            <div class="alert alert-danger">
              <p>Please fix the errors below:</p>
              <ul class="stage-errors">
                #{("<li>#{msg}</li>" for msg in row.fails).join('')}
              </ul>
            </div>
          """
        else
          'Other'
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
      title: "Results"
      orderable: false
      searchable: false
      data: (row, type, val, meta) ->
        """
          Thermal Structural
        """
    }
    {
      orderable: false
      searchable: false
      data: (row, type, val, meta) ->
        """
          <a class="btn btn-default" href="awesim://sftp@#{row.staged_dir}/">
            <i class="fa fa-file-o"></i> Files
          </a>
        """
    }
    {
      orderable: false
      searchable: false
      data: (row, type, val, meta) ->
        if type == 'display'
          """
            <a class="btn btn-danger pull-right delete-session" href="#{row.links.self}" title="Delete #{row.id}" data-remote="true" data-method="delete" data-confirm="Are you sure you want to delete this session? This is <strong>irreversible</strong>!" rel="nofollow">
              <i class="fa fa-trash-o"></i> Delete
            </a>
          """
        else
          row.links.self
    }
  ]

#
# Rails unobtrusive Javascript
#

# Session add button
$(document).on {
  'ajax:success': (e, data, status, xhr) ->
    rowNode = sessTable.row.add(data.session).draw().node()
    $(rowNode).hide().fadeIn('slow')
    noty
      text: 'Session was successfully created.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Session failed to be created: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '#new_session'

# Session delete button
$(document).on {
  'confirm:complete': (e, answer) ->
    if answer
      $(@).attr 'disabled', 'disabled'
  'ajax:success': (e, data, status, xhr) ->
    sessTable.row( $(@).parents('tr') ).remove().draw()
    noty
      text: 'Session was successfully deleted.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Session failed to be deleted: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '.delete-session'
