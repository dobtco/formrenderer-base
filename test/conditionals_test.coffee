describe 'Conditionals', ->
  beforeEach ->
    $('body').html('<div data-formrenderer />')
    @fr = new FormRenderer Fixtures.FormRendererOptions.CONDITIONAL()

    @visiblePageNumbers = ->
      $('.fr_pagination li').map ->
        parseInt($(@).text())
      .get()

    @activePage = ->
      @fr.state.get('activePage')

    @activePageNumber = ->
      parseInt($('.fr_pagination li span').text())

  it 'renders ok', ->
    expect(@fr).to.be.ok

  it 'renders with existing values', ->
    $('body').html('<div data-formrenderer />')
    data = Fixtures.FormRendererOptions.CONDITIONAL()
    data.response_fields[0].options[0].checked = false
    data.response_fields[0].options[1].checked = true
    @fr = new FormRenderer data

    expect(
      $('.fr_response_field:contains("Dang, that sucks.")').is(':visible')
    ).to.equal(true)

  it 'checks multiple conditions', ->
    $('body').html('<div data-formrenderer />')
    @fr = new FormRenderer Fixtures.FormRendererOptions.CONDITIONAL_THREE()

    isVisible = ->
      $('.fr_response_field:contains("Why do you like the word")').is(':visible')

    expect(isVisible()).to.equal(false)
    check 'Question 1', 'Yes'
    expect(isVisible()).to.equal(false)
    check 'Question 2', 'No'
    expect(isVisible()).to.equal(false)
    check 'Question 2', 'Yes'
    expect(isVisible()).to.equal(true)

  it 'can match on any', ->
    $('body').html('<div data-formrenderer />')
    @fr = new FormRenderer Fixtures.FormRendererOptions.CONDITIONAL_THREE_ANY()

    isVisible = ->
      $('.fr_response_field:contains("Why do you like the word")').is(':visible')

    expect(isVisible()).to.equal(false)
    check 'Question 1', 'Yes'
    expect(isVisible()).to.equal(true)
    check 'Question 2', 'No'
    expect(isVisible()).to.equal(true)
    check 'Question 2', 'Yes'
    expect(isVisible()).to.equal(true)
    uncheck 'Question 1', 'Yes'
    uncheck 'Question 2', 'Yes'
    expect(isVisible()).to.equal(false)

  it 'does not show hidden fields', ->
    expect(
      $('.fr_response_field:contains("Dang, that sucks.")').is(':visible')
    ).to.equal(false)

    select 'Do you like conditional form fields?', 'No'

    expect(
      $('.fr_response_field:contains("Dang, that sucks.")').is(':visible')
    ).to.equal(true)

  it 'does not trigger validations on hidden fields', ->
    expect(@fr.validate()).to.equal(true)

  describe 'repeating groups', ->
    it 'can be conditional', ->
      $('body').html('<div data-formrenderer />')

      @fr = new FormRenderer(
        project_id: 'dummy_val'
        response:
          id: 'xxx'
          responses: {}
        response_fields: [
          id: 1
          field_type: 'dropdown'
          label: 'Do you have dependents?'
          options: [
            { label: 'Yes' }
            { label: 'No' }
          ]
        ,
          id: 2
          field_type: 'repeating_group'
          label: 'List your depdendents'
          children: [
            {
              id: 3
              field_type: 'text',
              label: 'Name'
            }
          ]
          conditions: [
            response_field_id: 1
            method: 'eq'
            value: 'Yes'
          ]
        ]
      )

      expect($('.fr_response_field_3').is(':visible')).to.equal(true)
      select 'Do you have dependents?', 'No'
      expect($('.fr_response_field_3').is(':visible')).to.equal(false)

    it 'can contain conditions inside of entries', ->
      $('body').html('<div data-formrenderer />')

      @fr = new FormRenderer(
        project_id: 'dummy_val'
        response:
          id: 'xxx'
          responses: {}
        response_fields: [
          id: 1
          field_type: 'repeating_group'
          label: 'List your depdendents'
          children: [
            {
              id: 2
              field_type: 'text',
              label: 'Name'
            },
            {
              id: 3
              field_type: 'text',
              label: 'Age'
              conditions: [
                response_field_id: 2
                method: 'eq'
                value: 'Carl'
              ]
            }
          ]
        ]
      )

      expect($('.fr_response_field_3').is(':visible')).to.equal(false)
      fillIn 'Name', 'Carl'
      expect($('.fr_response_field_3').is(':visible')).to.equal(true)
      $('.js-add-entry').click()
      expect($('.fr_response_field_3').first().is(':visible')).to.equal(true)
      expect($('.fr_response_field_3').last().is(':visible')).to.equal(false)

  describe 'pagination', ->
    it 'only shows visible pages', ->
      expect(@visiblePageNumbers()).to.eql([1, 2])

    it 'changes pages via next/previous', ->
      # Without middle page
      expect(@activePage()).to.eql(1)
      expect(@activePageNumber()).to.eql(1)
      $('button:contains("Next page")').click()
      expect(@activePage()).to.eql(3)
      expect(@activePageNumber()).to.eql(2)
      $('button:contains("Back to page 1")').click()
      expect(@activePage()).to.eql(1)
      expect(@activePageNumber()).to.eql(1)

      fillIn 'Guess a number...', '6'

      # With middle page
      expect(@activePage()).to.eql(1)
      expect(@activePageNumber()).to.eql(1)
      $('button:contains("Next page")').click()
      expect(@activePage()).to.eql(2)
      expect(@activePageNumber()).to.eql(2)
      fillIn 'Why do you like big numbers?', 'asdf'
      $('button:contains("Next page")').click()
      expect(@activePage()).to.eql(3)
      expect(@activePageNumber()).to.eql(3)
      $('button:contains("Back to page 2")').click()
      expect(@activePage()).to.eql(2)
      expect(@activePageNumber()).to.eql(2)
      $('button:contains("Back to page 1")').click()
      expect(@activePage()).to.eql(1)
      expect(@activePageNumber()).to.eql(1)

    it 'changes pages via pagination links', ->
      expect(@activePage()).to.eql(1)
      expect(@activePageNumber()).to.eql(1)
      $('.fr_pagination li a:contains("2")').click()
      expect(@activePage()).to.eql(3)
      expect(@activePageNumber()).to.eql(2)
      $('.fr_pagination li a:contains("1")').click()
      expect(@activePage()).to.eql(1)
      expect(@activePageNumber()).to.eql(1)

  describe '#getValue', ->
    it 'only serializes the values of visible fields', ->
      expect(_.size(@fr.getValue())).to.equal(5)

      # With another visible
      fillIn 'Guess a number...', '6'
      expect(_.size(@fr.getValue())).to.equal(6)

      # Back to not visible
      fillIn 'Guess a number...', '5'
      expect(_.size(@fr.getValue())).to.equal(5)

describe 'ConditionChecker', ->
  it 'handles an invalid condition', ->
    conditional =
      method: 'eq'
      value: 'asdf'
      response_field_id: '99999'

    checker = new FormRenderer.ConditionChecker(
      @fr.formComponents.get(conditional.response_field_id),
      conditional
    )

    expect(checker.isVisible()).to.eql(true)

  describe 'values', ->
    it 'gets the text value for each response field', ->
      for key, field of Fixtures.Conditional.values
        for testValues in field.tests
          model = new FormRenderer.Models["ResponseField#{_.str.classify(key)}"](
            field.attrs || {}
          )
          model.setExistingValue testValues.in
          expect(model.toText()).to.eql(testValues.out)

  describe 'methods', ->
    beforeEach ->
      @fr = new FormRenderer Fixtures.FormRendererOptions.SHORT()

    it 'initializes directly from a field', ->
      conditional =
        method: 'eq'
        value: '123'
        response_field_id: '35'

      field = @fr.formComponents.get('35')

      checker = new FormRenderer.ConditionChecker(field, conditional)
      expect(checker.isVisible()).to.eql(false)

      field.setExistingValue('123')

      checker = new FormRenderer.ConditionChecker(field, conditional)
      expect(checker.isVisible()).to.eql(true)


    it 'calculates', ->
      for method, deets of Fixtures.Conditional.methods
        conditional =
          method: method
          value: deets.value
          response_field_id: '35'

        checker = new FormRenderer.ConditionChecker(
          @fr.formComponents.get(conditional.response_field_id),
          conditional
        )

        for x in deets.true
          checker.value = x
          expect(checker.isVisible()).to.eql(true)

        for x in deets.false
          checker.value = x
          expect(checker.isVisible()).to.eql(false)
