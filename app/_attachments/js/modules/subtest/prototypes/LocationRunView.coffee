class LocationRunView extends Backbone.View

  className: "LocationRunView"

  events:
    "click .school_list li" : "autofill"
    "keyup input"  : "showOptions"
    "click .clear" : "clearInputs"
    "change select" : "onSelectChange"

  initialize: (options) ->
    
    @model  = @options.model
    @parent = @options.parent
    
    @levels = @model.get("levels")       || []
    @locations = @model.get("locations") || []

    if @levels.length == 1 && @levels[0] == ""
      @levels = []
    if @locations.length == 1 && @locations[0] == ""
      @locations = []

    @haystack = []

    for location, i in @locations
      @haystack[i] = []
      for locationData in location
        @haystack[i].push locationData.toLowerCase()

    template = "<li data-index='{{i}}'>"
    for level, i in @levels
      template += "{{level_#{i}}}"
      template += " - " unless i == @levels.length-1
    template += "</li>"
    
    @li = _.template(template)

  clearInputs: ->
    for level, i in @levels
      @$el.find("#level_#{i}").val("")

  autofill: (event) ->
    @$el.find(".autofill").fadeOut(250)
    index = $(event.target).attr("data-index")
    location = @locations[index]
    for level, i in @levels
      @$el.find("#level_#{i}").val(location[i])


  showOptions: (event) ->
    needle = $(event.target).val().toLowerCase()
    field = parseInt($(event.target).attr('data-level'))
    # hide if others are showing
    for otherField in [0..@haystack.length]
      @$el.find("#autofill_#{otherField}").hide()

    atLeastOne = false
    results = []
    for stack, i in @haystack
      isThere = ~@haystack[i][field].indexOf(needle)
      results.push i if isThere
      atLeastOne = true if isThere
    
    for stack, i in @haystack
      for otherField, j in stack
        if j == field
          continue
        isThere = ~@haystack[i][j].indexOf(needle)
        results.push i if isThere && !~results.indexOf(i)
        atLeastOne = true if isThere
    
    if atLeastOne
      html = ""
      for result in results
        html += @getLocationLi result
      @$el.find("#autofill_#{field}").fadeIn(250)
      @$el.find("#school_list_#{field}").html html

    else
      @$el.find("#autofill_#{field}").fadeOut(250)

  getLocationLi: (i) ->
    templateInfo = "i" : i
    for location, j in @locations[i]
      templateInfo["level_" + j] = location
    return @li templateInfo

  render: ->
    schoolListElements = ""

    html = "
      <button class='clear command'>#{t('clear')}</button>
      ";


    if @typed
      for level, i in @levels
        html += "
          <div class='label_value'>
            <label for='level_#{i}'>#{level}</label><br>
            <input data-level='#{i}' id='level_#{i}' value=''>
          </div>
          <div id='autofill_#{i}' class='autofill' style='display:none'>
            <h2>#{t('select one from autofill list')}</h2>
            <ul class='school_list' id='school_list_#{i}'>
            </ul>
          </div>
      "
    else
      for level, i in @levels
        
        levelOptions = @getOptions(i)

        isDisabled = i isnt 0 && "disabled='disabled'"

        html += "
          <div class='label_value'>
            <label for='level_#{i}'>#{level}</label><br>
            <select id='level_#{i}' data-level='#{i}' #{isDisabled||''}>
              #{levelOptions}
            </select>
          </div>
        "

    @$el.html html

    @trigger "rendered"
    @trigger "ready"

  onSelectChange: (event) ->
    $target = $(event.target)
    levelChanged = parseInt($target.attr("data-level"))
    newValue = $target.val()
    nextLevel = levelChanged + 1
    if levelChanged isnt @levels.length
      @$el.find("#level_#{nextLevel}").removeAttr("disabled")
      @$el.find("#level_#{nextLevel}").html @getOptions(nextLevel, newValue)

  getOptions: (index, selected = '')->

    doneOptions = []
    levelOptions = ''

    lastIndex = index - 1

    for location in @locations
      unless ~doneOptions.indexOf location[index]
        isNotChild = selected is ''
        isValidChild = selected is location[lastIndex]
        if isNotChild or isValidChild
          doneOptions.push location[index]
          levelOptions += "<option value='#{location[index]}'>#{location[index]}</option>"
    "<option selected='selected' disabled='disabled'>Please select a #{@levels[index]}</option>" + levelOptions


  getResult: ->
    return {
      "labels"   : (level.replace(/[\s-]/g,"_") for level in @levels)
      "location" : ($.trim(@$el.find("#level_#{i}").val()) for level, i in @levels)
    }

  getSkipped: ->
    return {
      "labels"   : (level.replace(/[\s-]/g,"_") for level in @levels)
      "location" : ("skipped" for level, i in @levels)
    }


  isValid: ->
    @$el.find(".message").remove()
    inputs = @$el.find("input")
    selects = @$el.find("select")
    elements = if selects.length > 0 then selects else inputs
    for input, i in elements
      return false if _($(input).val()).isEmptyString()
    true

  showErrors: ->
    inputs = @$el.find("input")
    selects = @$el.find("select")
    elements = if selects.length > 0 then selects else inputs
    for input in elements
      if _($(input).val()).isEmptyString()
        $(input).after " <span class='message'>#{$('label[for='+$(input).attr('id')+']').text()} must be filled.</span>"

  getSum: ->
    counts =
      correct   : 0
      incorrect : 0
      missing   : 0
      total     : 0
      
    for input in @$el.find("input")
      $input = $(input)
      counts['correct']   += 1 if ($input.val()||"") != ""
      counts['incorrect'] += 0 if false
      counts['missing']   += 1 if ($input.val()||"") == ""
      counts['total']     += 1 if true

    return {
      correct   : counts['correct']
      incorrect : counts['incorrect']
      missing   : counts['missing']
      total     : counts['total']
    }
