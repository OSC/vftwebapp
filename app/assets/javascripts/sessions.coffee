# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

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
      title: 'Created'
      data: (row, type, val, meta) ->
        if type == 'display' || type == 'filter'
          return moment(row.created_at).format('lll')
        else
          return row.created_at
    }
    {
      orderable: false
      searchable: false
      data: (row, type, val, meta) ->
        if type == 'display'
          return """
            <a class="btn btn-danger pull-right delete-session" href="#{row.link}" title="Delete #{row.id}" data-remote="true" data-method="delete" data-confirm="Are you sure you want to delete this session? This is <strong>irreversible</strong>!" rel="nofollow">
              <i class="fa fa-trash-o"></i> Delete
            </a>
          """
        else
          return row.link
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
