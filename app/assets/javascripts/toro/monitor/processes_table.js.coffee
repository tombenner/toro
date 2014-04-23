class ToroMonitor.ProcessesTable extends ToroMonitor.AbstractJobsTable

  initialize: =>
    @options =
      table_selector: 'table.processes'
      columns:
        id: 0
        started_by: 1
        queue: 2
        class_name: 3
        name: 4
        created_at: 5
        started_at: 6
        duration: 7
        message: 8
        status: 9
        properties: 10
        args: 11
      column_options: [
        { bVisible: false }
        {
          fnRender: (oObj) =>
            """<span class="nowrap">#{oObj.aData[@columns.started_by]}</span>"""
        }
        null
        null
        { bSortable: false }
        {
          fnRender: (oObj) =>
            @format_time_ago(oObj.aData[@columns.created_at])
        }
        {
          fnRender: (oObj) =>
            @format_time_ago(oObj.aData[@columns.started_at])
        }
        null
        { bSortable: false }
        {
          fnRender: (oObj) =>
            status = oObj.aData[@columns.status]
            class_name = switch status
              when 'failed'
                'danger'
              when 'complete'
                'success'
              when 'running'
                'primary'
              else
                'info'
            html = """<a href="#" class="btn btn-#{class_name} btn-mini status-value">#{oObj.aData[@columns.status]}</a>"""
            if status == 'failed'
              html += """<a href="#" class="btn btn-mini btn-primary retry-job" data-job-id="#{oObj.aData[@columns.id]}">Retry<a>"""
            """<span class="action-buttons">#{html}</span>"""
        }
        { bVisible: false }
        { bVisible: false }
      ]
    
    return null unless $(@options.table_selector).length

    @table = $(@options.table_selector)

    @columns = @options.columns
    @status_filter = null

    @table.dataTable
      bProcessing: true
      bServerSide: true
      sAjaxSource: @table.data('source')
      iDisplayLength: 10
      aaSorting: [[@columns.created_at, 'desc']]
      sPaginationType: 'bootstrap'
      aoColumns: @options.column_options
      oLanguage:
        sInfo: '_TOTAL_ jobs'
        sInfoFiltered: ' (filtered from _MAX_)'
        sLengthMenu: 'Per page: _MENU_'
        sSearch: ''
      fnRowCallback: (nRow, aData, iDisplayIndex) =>
        $('.timeago', nRow).timeago()
      fnInitComplete: () =>
        filter_container = @table.siblings('.dataTables_filter')
        filter_container.find('input').attr('placeholder', 'Search...')
      fnServerData: (sSource, aoData, fnCallback) =>
        $.each @api_params, (key, value) =>
          aoData.push
            name: key
            value: @api_params[key]
        $.getJSON sSource, aoData, (json) -> fnCallback(json)

    @table.parents('.dataTables_wrapper').addClass('jobs-table-wrapper')

    @initialize_ui()

$ ->
  new ToroMonitor.ProcessesTable