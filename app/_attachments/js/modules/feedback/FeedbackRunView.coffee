class Namespace
  constructor: (options) ->
    @[key] = value for key, value of options

class NotesView extends Backbone.EditView

  className : "NotesView"

  initialize: ( options ) ->
    @model = options.model
    @models = new Backbone.Collection [@model]

  render: ->
    @$el.html @getEditable(@model, { key : 'notes' },'Notes', 'Tap here to edit')


class FeedbackRunView extends Backbone.View

  className: "FeedbackRunView"

  initialize: (options) ->
    @[key] = value for key, value of options
    @noteViews = []

  render: ->
    html = ""
    shownCount = 0

    @feedback.collection.each (critique, i) =>

      namespace = new Namespace
        critique : critique
        trip     : @trip

      try 
        shouldDisplay = CoffeeScript.eval.apply(namespace, [critique.getString("when")])
      catch e
        Utils.midAlert "Show when code error in #{critique.getString("name")}<br>#{e}"

      return unless shouldDisplay

      try
        CoffeeScript.eval.apply(namespace, [critique.getString("processingCode")])
      catch e
        Utils.midAlert "Processing code error in #{critique.getString("name")}<br>#{e}"
      
      try
        template = _.template critique.getString("template")
      catch e
        Utils.midAlert "Error parsing template in #{critique.getString("name")}<br>#{e}"


      try

        firstThreeClass = if shownCount >= 1 and shownCount <= 3 then " class='three'" else ''
        html += "
        <div#{firstThreeClass}>
          <h3>#{critique.getString('name')}</h3>
          <p>#{template(namespace)}</p>
        </div>
        "
      catch e
        Utils.midAlert "Error compiling template in #{critique.getString("name")}<br>#{e}"

      if critique.shouldShowNotes()

        html += "<div class='notes NotesView' data-model-id='#{critique.id}'></div>"

      shownCount++


    @$el.html "<section>#{html}</section>"


    $notes = @$el.find(".notes")
    if $notes.length > 0
      $notes.each (i, note) =>

        model = new Result
          "_id" : @feedback.id + @trip.id

        noteView = new NotesView
          model: model
        noteView.setElement $(note)
        @noteViews.push noteView
        
        model.fetch
          success: ->
            noteView.render()
          error: =>
            model.save
              'tripId' : @trip.id
            ,
              success: ->
               noteView.render()

    @trigger "rendered"

  onClose: ->
    for view in @noteViews
      view.close()

















