# Place all the DataTables related behaviors and hooks here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# Live DOM ordering (http://www.datatables.net/examples/plug-ins/dom_sort.html)
# Create an array with the values of all the span's in a column
# $.fn.dataTable.ext.order['dom-text'] = (settings, col) ->
#   @api().column(col, order: 'index').nodes().map (td, i) ->
#     $('span', td).text()

jQuery ->
  # Set up datatable
  window.meshTable = $('.data-table').DataTable()
