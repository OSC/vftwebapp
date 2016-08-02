# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


# Only run in Sessions index page
return unless $('#new_session').length && $('#sessions_table').length

#
# Timer object
#

timers = {}

class Timer
  constructor: (@callback, @delay) ->
    @remaining = @delay
    @active = true
    @resume()
  resume: () ->
    return unless @active
    @start = new Date()
    clearTimeout(@timerId)
    @timerId = setTimeout(@callback, @remaining)
  restart: () ->
    return unless @active
    @remaining = @delay
    @resume()
  pause: () ->
    return unless @active
    clearTimeout(@timerId)
    @remaining -= new Date() - @start
  stop: () ->
    return unless @active
    clearTimeout(@timerId)
    @active = false

#
# Datatables
#

# Set up datatable
sessTable = $('#sessions_table').DataTable
  ajax:
    url: $(@).data('url')
    dataSrc: 'sessions'
  pageLength: 50
  order: [[ 1, 'desc' ]]
  rowId: 'id'
  columns: [
    {
      orderable: false
      searchable: false
      data: (row, type, val, meta) ->
        if row.status.not_submitted
          """
            <p>
              <a class="btn btn-success launch-session" href="#{row.links.edit}" data-remote="true">
                <i class="fa fa-play-circle"></i> Launch
              </a>
            </p>
            <div class="btn-group" role="group" aria-label="...">
              <a class="btn btn-default back-session" href="#{row.links.back}" data-remote="true" data-method="patch"#{' disabled="disabled"' if row.stage.step == 1}>
                <i class="fa fa-step-backward"></i> Back
              </a>
              <a class="btn btn-default skip-session" href="#{row.links.skip}" data-remote="true" data-method="patch"#{' disabled="disabled"' if row.stage.step == 4}>
                Skip <i class="fa fa-step-forward"></i>
              </a>
            </div>
          """
        else if row.status.active
          """
            <p>
              <a class="btn btn-danger stop-session" href="#{row.links.stop}" title="Stop #{row.id}" data-remote="true" data-method="patch" data-confirm="Are you sure you want to stop this session?" rel="nofollow">
                <i class="fa fa-stop-circle"></i> Stop
              </a>
            </p>
            <div class="btn-group" role="group" aria-label="...">
              <a class="btn btn-default back-session" href="#{row.links.back}" data-remote="true" data-method="patch" disabled="disabled">
                <i class="fa fa-step-backward"></i> Back
              </a>
              <a class="btn btn-default skip-session" href="#{row.links.skip}" data-remote="true" data-method="patch" disabled="disabled">
                Skip <i class="fa fa-step-forward"></i>
              </a>
            </div>
          """
        else if row.status.failed
          """
            <p>
              <a class="btn btn-default validate-session" href="#{row.links.validate}" data-remote="true" data-method="patch" rel="nofollow">
                <i class="fa fa-check-square-o"></i> Try again</i>
              </a>
            </p>
            <div class="btn-group" role="group" aria-label="...">
              <a class="btn btn-default back-session" href="#{row.links.back}" data-remote="true" data-method="patch">
                <i class="fa fa-step-backward"></i> Back
              </a>
              <a class="btn btn-default skip-session" href="#{row.links.skip}" data-remote="true" data-method="patch" disabled="disabled">
                Skip <i class="fa fa-step-forward"></i>
              </a>
            </div>
          """
        else
          """
            <p>
              <button class="btn btn-success launch-session disabled">
                <i class="fa fa-play-circle"></i> Launch
              </button>
            </p>
            <div class="btn-group" role="group" aria-label="...">
              <a class="btn btn-default back-session" href="#{row.links.back}" data-remote="true" data-method="patch">
                <i class="fa fa-step-backward"></i> Back
              </a>
              <a class="btn btn-default skip-session" href="#{row.links.skip}" data-remote="true" data-method="patch" disabled="disabled">
                Skip <i class="fa fa-step-forward"></i>
              </a>
            </div>
          """
    }
    {
      title: 'Id'
      data: 'id'
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
          row.status.name
    }
    {
      orderable: false
      searchable: false
      className: 'workflow-column'
      data: (row, type, val, meta) ->
        if row.status.active
          msg = '<div class="alert alert-info">'
          if row.stage.step == 1 && row.links.conn
            msg += """
              <p>
                <a href="#{row.links.conn}" class="btn btn-default">
                  <i class="fa fa-desktop"></i> Open VFTSolid
                </a>
              </p>
              <p>
                When you are done exporting CTSP, WARP3D, and VFTr files, feel free to click the "Stop" button to carry on.
              </p>
            """
          else if row.status.percent
            msg += """
              <div class="progress">
                <div class="progress-bar progress-bar-primary progress-bar-striped" role="progressbar" style="width: #{row.status.percent}%">
                  #{row.status.percent}%
                </div>
              </div>
            """
          else
            msg += 'Job is submitted...'
          msg
        else if row.status.not_submitted
          """
            <p>
              This job needs to be submitted for you to continue on in the workflow.
            </p>
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
        else if row.status.complete
          """
            <div class="alert alert-success">
              <p>Your simulation has completed successfully.</p>
            </div>
          """
        else
          'Something bad has happened. You should not see this.'
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
        msg = """
          <p>
            <a class="btn btn-default submit-thermal-paraview paraview-popover" href="#{row.links.t_paraview}" data-remote="true"#{' disabled="disabled"' unless row.links.t_paraview}>
              Thermal
            </a>
          </p><p>
            <a class="btn btn-default submit-structural-paraview paraview-popover" href="#{row.links.s_paraview}" data-remote="true"#{' disabled="disabled"' unless row.links.s_paraview}>
              Structural
            </a>
          </p>
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
  rowCallback: (row, data, index) ->
    if data.status.active
      timers[data.id] = new Timer (->
        timers[data.id].stop() # set state of timer to be stopped
        $.getJSON(data.links.self).done((data) ->
          # update row
          sessTable.row(row).data(data.session).draw()
        ).fail(->
          # do nothing
          console.log "Error getting info for id = #{data.id}"
        )
      ), 5000 if !timers[data.id] || !timers[data.id].active

#
# Handle timers with modals
#

$(document).on {
  'show.bs.modal': ->
    for k, v of timers
      v.pause() # pause timers
    return
  'hidden.bs.modal': ->
    for k, v of timers
      v.resume() # resume timers
}


#
# Refresh table
#

$(document).on {
  'click': ->
    sessTable.ajax.reload null, false
}, '.reload-sessions'

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
      for k, v of timers
        v.pause() # pause timers
      $(@).attr 'disabled', 'disabled'
    return
  'ajax:success': (e, data, status, xhr) ->
    id = $(@).parents('tr').attr('id')
    for k, v of timers
      v.stop() if k == id
      v.restart() # resume timers
    sessTable.row( $(@).parents('tr') ).remove().draw()
    noty
      text: 'Session was successfully deleted.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    for k, v of timers
      v.resume() # resume timers
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


# Session submit button
$(document).on {
  'click': ->
    $(@).attr 'disabled', 'disabled'
    $(@).parents('form').submit()
}, '.submit-session:not([disabled])'

$(document).on {
  'ajax:success': (e, data, status, xhr) ->
    $('#session_submit_modal').modal('hide')
    sessTable.row( $('#' + data.session.id) ).data(data.session).draw()
    noty
      text: 'Session was successfully submitted.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).find('.submit-session').removeAttr 'disabled'
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Session failed to be submitted: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '#session_submit_modal form'

# Session stop button
$(document).on {
  'confirm:complete': (e, answer) ->
    if answer
      for k, v of timers
        v.pause() # pause timers
      $(@).attr 'disabled', 'disabled'
    return
  'ajax:success': (e, data, status, xhr) ->
    id = $(@).parents('tr').attr('id')
    for k, v of timers
      v.stop() if k == id
      v.restart() # resume timers
    sessTable.row( $(@).parents('tr') ).data(data.session).draw()
    noty
      text: 'Session was successfully stopped.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    for k, v of timers
      v.resume() # resume timers
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Session failed to be stopped: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '.stop-session'


# Session validate button
$(document).on {
  'click': ->
    $(@).attr 'disabled', 'disabled'
  'ajax:success': (e, data, status, xhr) ->
    sessTable.row( $(@).parents('tr') ).data(data.session).draw()
    noty
      text: 'The session validation ran without problems.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Session failed to be validated: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '.validate-session'

# Session back button
$(document).on {
  'click': ->
    $(@).attr 'disabled', 'disabled'
  'ajax:success': (e, data, status, xhr) ->
    sessTable.row( $(@).parents('tr') ).data(data.session).draw()
    noty
      text: 'The session was reset back a stage successfully.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Session failed to be reset back a stage: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '.back-session'

# Session skip button
$(document).on {
  'click': ->
    $(@).attr 'disabled', 'disabled'
  'ajax:success': (e, data, status, xhr) ->
    sessTable.row( $(@).parents('tr') ).data(data.session).draw()
    noty
      text: 'The session skipped to the next stage successfully.'
      type: 'success'
      theme: 'relax'
      timeout: 2000
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Session failed to skip to the next stage: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '.skip-session'

# Session launch button
$(document).on {
  'click': ->
    $('#session_submit_modal').html(
      """
        <div class="modal-dialog" role="document">
          <div class="modal-content">
            <div class="modal-body">
              Loading...
            </div>
          </div>
        </div>
      """
    )
    $('#session_submit_modal').modal('show')
}, '.launch-session:not([disabled])'

# Submit thermal paraview for session
$(document).on {
  'click': ->
    $(@).attr 'disabled', 'disabled'
  'ajax:before': ->
    href = $(@).attr 'href'
    resx = parseInt(window.screen.width  * 0.8)
    resy = parseInt(window.screen.height * 0.8)
    $(@).attr 'href', "#{href}?session[resx]=#{resx}&session[resy]=#{resy}"
  'ajax:success': (e, data, status, xhr) ->
    $(@).removeAttr 'disabled'
    $(@).popover(
      placement: 'top'
      html: true
      content: """
        <a href="#{data.link}" class="btn btn-primary">
          Launch with AweSim Connect
        </a>
      """
    ).popover('show')
  'ajax:error': (e, xhr, status, error) ->
    $(@).removeAttr 'disabled'
    errors = xhr.responseJSON? && xhr.responseJSON.errors || []
    noty
      text: """
        Failed to launch paraview session: #{error}<br />
        <ul class="notify-errors">
        #{("<li>#{msg}</li>" for msg in errors).join('')}
        </ul>
      """
      type: 'error'
      theme: 'relax'
}, '.submit-thermal-paraview,.submit-structural-paraview'

# Destroy all paraview popovers if user clicks anywhere
$(document).on {
  'click': ->
    $('.paraview-popover').popover 'destroy'
}
