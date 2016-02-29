###
Unobtrusive JavaScript solution for polling in a Rails application
Introduction:
Add a polling-placeholder wrapper div to any partial and add a data attribute
named poll that should be equal to "true" until you want to stop polling.
The default polling frequency will be used unless you provide an "interval" data
attribute which should be the number of milliseconds to use for the interval.
The name of the partial to render should be provided in the url params.
Example partial:
<div class="polling-placeholder">
  <div id="foo_1" class="object" data-poll="true" data-url="/foo/1?partial=bar" data-interval="500">
    <p>Hello World</p>
  </div>
</div>
Example controller:
class FooController < ApplicationController
  def show
    @foo = Foo.find(params[:id])
    respond_to do |format|
      render partial: "foos/#{params[:partial]}", locals: { foo: @foo }
    end
  end
end
###

class Poller

  constructor: (@elem) ->

  interval: ->
    $(@elem).data("interval") ? 3000

  url: ->
    $(@elem).data("url")

  indices: ->
    $(@elem).find("[data-poll='true']").map (i, elem) ->
      $(elem).data('id')
    .toArray()

  start: ->
    @intervalId = setInterval(@request, @interval())

  request: =>
    $.ajax(url: @url(), data: { session_list: true, session_ids: @indices() }, dataType: 'script')

  # request: =>
  #   $.ajax(url: @url(), dataType: "script").always (data) =>
  #     @replace(data.responseText) if data.status == 200

  replace: (responseText) ->
    placeholder = $(responseText)
    partial = $($(responseText).html())
    $("div#" + $(@elem).attr("id")).closest("div.polling-placeholder").html(placeholder.html())
    @stop() unless partial.data("poll")

  stop: ->
    clearInterval(@intervalId)

$ ->
  $("[data-poller='true']").each (i, elem) ->
    new Poller(elem).start()
