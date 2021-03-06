FormRenderer.Models.ResponseFieldRepeatingGroup = FormRenderer.Models.BaseFormComponent.extend
  group: true
  field_type: 'repeating_group'

  initialize: ->
    FormRenderer.Models.BaseFormComponent::initialize.apply @, arguments
    @entries = []

  validateComponent: ->
    for entry in @entries
      entry.formComponents.invoke('validateComponent')

  setExistingValue: (entryValues) ->
    if @isRequired()
      # If the field is required, ensure that there is at least one value present
      if !entryValues || entryValues.length == 0
        entryValues = [{}]

    else # Field is optional...
      # If entryValues is not set, then add an empty value.
      if !entryValues
        entryValues = [{}]
      # If entryValues is an empty array, the field is skipped.
      else if _.isArray(entryValues) && _.isEmpty(entryValues)
        @set('skipped', true)

    @entries = _.map entryValues, (value) =>
      new FormRenderer.Models.ResponseFieldRepeatingGroupEntry({ value }, @fr, @)

  addEntry: ->
    @entries.push(
      new FormRenderer.Models.ResponseFieldRepeatingGroupEntry({}, @fr, @)
    )

    @fr.responsesChanged()

  removeEntry: (idx) ->
    @entries.splice(idx, 1)

    if @entries.length == 0
      @set('skipped', true)

    @fr.responsesChanged()

  isSkipped: ->
    !!@get('skipped')

  getValue: ->
    if @isSkipped()
      []
    else
      _.invoke @entries, 'getValue'

  getTruncatedDescription: ->
    description = @get('description')
    truncation_length = 140

    if description && description.length > truncation_length
      description = description.substr(0, truncation_length).trim() + '…'

    description

  maxEntries: ->
    if @get('maxentries')
      parseInt(@get('maxentries'), 10) || Infinity
    else
      Infinity

  canAdd: ->
    @entries.length < @maxEntries()

FormRenderer.Models.ResponseFieldRepeatingGroupEntry = Backbone.Model.extend
  field_type: 'repeating_group_entry'

  initialize: (_attrs, @fr, @repeatingGroup) ->
    children = @repeatingGroup.get('children')
    unless children?
      children = []
    @initFormComponents children, @get('value') || {}

  reflectConditions: ->
    @view.reflectConditions()

  canRemove: ->
    @repeatingGroup.entries.length > 1

FormRenderer.Views.ResponseFieldRepeatingGroup = Backbone.View.extend
  className: 'fr_response_field fr_response_field_group'

  events:
    'click .js-remove-entry': 'removeEntry'
    'click .js-add-entry': 'addEntry'
    'click .js-skip': 'toggleSkip'

  initialize: (options) ->
    @_sharedInitialize(options)

    # Forward `shown` and `hidden` events to subviews
    @on 'shown', => view.trigger('shown') for view in @views
    @on 'hidden', => view.trigger('hidden') for view in @views

  toggleSkip: ->
    @model.set('skipped', !@model.isSkipped())

    # When clicking "answer this question", add an entry if there are none
    if !@model.isSkipped() && @model.entries.length == 0
      @addEntry()

    @form_renderer.responsesChanged()

    @render()

  addEntry: ->
    @model.addEntry()
    @render()
    _.last(@views).focus()

  removeEntry: (e) ->
    idx = @$el.find('.js-remove-entry').index(e.target.closest('.js-remove-entry'))
    @model.removeEntry(idx)
    @render()

  render: ->
    @views = []
    $els = $()

    for entry, idx in (@model.entries || [])
      view = new FormRenderer.Views.ResponseFieldRepeatingGroupEntry(
        entry: entry,
        form_renderer: @form_renderer,
        idx: idx
      )

      entry.view = view
      $els = $els.add view.render().el
      @views.push view

    @$el.html JST['partials/repeating_group'](@)

    @$el.removeClass('is_truncated')
    if (@model.entries.length && @model.entries[0].formComponents.length > 0)
      @$el.addClass('is_truncated')

    rivets.bind @$el, { @model }
    @$el.find('.fr_group_entries').append($els)
    @form_renderer?.trigger 'viewRendered', @
    @

FormRenderer.Views.ResponseFieldRepeatingGroupEntry = Backbone.View.extend
  className: 'fr_group_entry'

  initialize: (options) ->
    @entry = options.entry
    @form_renderer = options.form_renderer
    @idx = options.idx
    @views = []

    # Forward `shown` and `hidden` events to subviews
    @on 'shown', => view.trigger('shown') for view in @views
    @on 'hidden', => view.trigger('hidden') for view in @views

  render: ->
    @$el.html JST['partials/repeating_group_entry'](@)
    @form_renderer?.trigger 'viewRendered', @
    $children = @$el.find('.fr_group_entry_fields')

    @entry.formComponents.each (rf) =>
      view = FormRenderer.buildFormComponentView(rf, @form_renderer)
      $children.append view.render().el
      view.reflectConditions()
      @views.push view

    @

  reflectConditions: ->
    for view in @views
      view.reflectConditions()

  focus: ->
    @views[0].focus()
