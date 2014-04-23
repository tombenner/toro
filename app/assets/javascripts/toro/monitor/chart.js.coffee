class ToroMonitor.Chart

  constructor: ->
    options =
      selector: '.chart'
      poll_interval: ToroMonitor.settings.poll_interval
    @initialize(options)

  initialize: (options) =>
    @options = options
    @width = 960
    @height = 580
    @padding = [120, 50, 30, 20]

    return null unless $(options.selector).length

    # These correspond to Job.statuses: queued, running, complete, failed, [custom statuses]
    colors = ['lightblue', 'blue', 'green', 'red', 'gray', 'purple', 'yellow']

    @color_scale = d3.scale.ordinal().range(colors)

    @x_scale = d3.scale.ordinal().rangeRoundBands([0, @width - @padding[1] - @padding[3]])
    @y_scale = d3.scale.linear().range([0, @height - @padding[0] - @padding[2]])
    @z_scale = d3.scale.ordinal().range(colors)

    @render()
    @start_polling()

  start_polling: =>
    setInterval =>
      if document.hasFocus()
        @render()
    , @options.poll_interval
    
  render: =>
    d3.json ToroMonitor.settings.api_url('jobs/chart'), (data) =>

      # Clear out the previously rendered chart 
      $(@options.selector).text('')

      queues = data.queues_status_counts.map (queues_status_count) -> queues_status_count.queue
      charts_config = ToroMonitor.settings.charts || { 'ALL': null }
      charts_config = @standardize_charts_config(charts_config, queues)
      
      for index, chart_config of charts_config
        chart_config['show_legend'] = true if index == '0'
        @render_chart(data, chart_config)

  render_chart: (data, chart_config) =>
    @svg = d3.select(@options.selector).append('svg:svg')
        .attr('width', @width)
        .attr('height', @height)
      .append('svg:g')
        .attr('transform', 'translate(' + @padding[3] + ',' + (@height - @padding[2]) + ')')

    statuses = data.statuses
    queues_status_counts = []
    for queue_status_counts in data.queues_status_counts
      if chart_config['queues'].indexOf(queue_status_counts.queue) > -1
        queues_status_counts.push queue_status_counts
    data = queues_status_counts
    
    @color_scale.domain(statuses)

    # Transpose the data into layers by queue
    queues = d3.layout.stack()(statuses.map( (queue) =>
      layers = []
      for d in data
        if d[queue]?
          layers.push {x: d.queue, y: d[queue]+0}
        else
          layers.push {x: d.queue, y: 0}
      layers
    ))

    # Compute the x-domain (by queue) and y-domain (by top).
    @x_scale.domain(queues[0].map( (d) => d.x))
    @y_scale.domain([0, d3.max(queues[queues.length - 1], (d) => d.y0 + d.y )])

    # Groups for queues
    queue = @svg.selectAll('g.queue')
        .data(queues)
      .enter().append('svg:g')
        .attr('class', 'queue')
        .style('fill', (d, i) => @z_scale(i) )
        .style('stroke', (d, i) => d3.rgb(@z_scale(i)).darker() )

    # Rects for queues
    rect = queue.selectAll('rect')
        .data(Object)
      .enter().append('svg:rect')
        .attr('x', (d) => @x_scale(d.x) )
        .attr('y', (d) => -@y_scale(d.y0) - @y_scale(d.y) )
        .attr('height', (d) => @y_scale(d.y) )
        .attr('width', @x_scale.rangeBand())
        .append('title')
          .text((d) => if d.y == 1 then "#{d.y} job" else "#{d.y} jobs")

    # Labels for queues
    label = @svg.selectAll('text')
        .data(@x_scale.domain())
      .enter().append('foreignObject')
        .attr('x', (d) => @x_scale(d) )
        .attr('y', 6)
        .attr('dy', '.71em')
        .attr('height', 20)
        .attr('width', @x_scale.rangeBand())
        .append('xhtml:div')
          .text((d) => d)
          .attr('style', 'font-size: 11px; text-align: center; word-wrap:break-word; padding: 0 3px')

    # Y-axis rules
    rule = @svg.selectAll('g.rule')
        .data(@y_scale.ticks(5))
      .enter().append('svg:g')
        .attr('class', 'rule')
        .attr('transform', (d) => 'translate(0,' + -@y_scale(d) + ')' )

    rule.append('svg:text')
        .attr('x', @width - @padding[1] - @padding[3] + 6)
        .attr('dy', '.35em')
        .text(d3.format(',d'))

    # Title
    if chart_config['title']
      label = @svg.selectAll('g.text').data(['Test 1']).enter()
        .append('text')
          .attr('x', 0)
          .attr('y', 90 - @height)
          .attr('height', 20)
          .attr('font-size', '24px')
          .attr('fill', '#777')
          .text(chart_config['title'])

    # Legend
    if chart_config['show_legend']
      legend_x = @width - 130
      legend_y = 30 - @height
      legend_box_width = 18
      legend_box_height = 18

      legend = @svg.selectAll('.legend')
          .data(@color_scale.domain().reverse().slice())
        .enter().append('g')
          .attr('class', 'legend')
          .attr('transform', (d, i) => 'translate(0,' + i * 20 + ')')

      # White background for the legend
      legend.append('rect')
          .attr('x', legend_x - 10)
          .attr('y', legend_y)
          .attr('width', legend_box_width + 100)
          .attr('height', legend_box_height + 10)
          .style('fill', '#fff')

      # Legend boxes
      legend.append('rect')
          .attr('x', legend_x)
          .attr('y', legend_y)
          .attr('width', legend_box_width)
          .attr('height', legend_box_height)
          .style('fill', @color_scale)

      # Legend labels
      legend.append('text')
          .attr('x', legend_x + 25)
          .attr('y', legend_y + 9)
          .attr('dy', '.35em')
          .text((d) => d)

  standardize_charts_config: (chart_config, queues) =>
    charts = []
    matched_queues = []
    for pattern, title of chart_config
      chart = {
        title: title
        pattern: pattern
      }
      if pattern == 'OTHER' || pattern == 'ALL'
        charts[pattern] = chart
        continue
      else
        pattern_queues = []
        for queue in queues
          re = new RegExp(pattern, 'i')
          if re.test(queue)
            pattern_queues.push queue
            matched_queues.push queue
        chart['queues'] = pattern_queues
      charts[pattern] = chart
    remaining_queues = @array_difference(queues, matched_queues)
    charts['OTHER']['queues'] = remaining_queues if charts['OTHER']
    charts['ALL']['queues'] = queues if charts['ALL']
    @object_values(charts)

  array_difference: (array1, array2) =>
    array1.filter (value) -> !(array2.indexOf(value) > -1)

  object_values: (object) =>
    value for key, value of object

$ ->
  new ToroMonitor.Chart