DOMListener = require '../src/dom-listener'

describe "DOMListener", ->
  [parent, child, grandchild, listener] = []

  beforeEach ->
    grandchild = document.createElement("div")
    grandchild.classList.add('grandchild')
    child = document.createElement("div")
    child.classList.add('child')
    parent = document.createElement("div")
    parent.classList.add('parent')
    child.appendChild(grandchild)
    parent.appendChild(child)

    document.querySelector('#jasmine-content').appendChild(parent)

    listener = new DOMListener(parent)

  describe "when an event is dispatched on an element covered by the listener", ->
    it "invokes callbacks associated with matching selectors along the event's bubble path", ->
      calls = []

      listener.add '.parent', 'event', (event) ->
        expect(this).toBe parent
        expect(event.target).toBe grandchild
        expect(event.currentTarget).toBe parent
        calls.push('parent')

      listener.add '.child', 'event', (event) ->
        expect(this).toBe child
        expect(event.target).toBe grandchild
        expect(event.currentTarget).toBe child
        calls.push('child')

      listener.add '.grandchild', 'event', (event) ->
        expect(this).toBe grandchild
        expect(event.target).toBe grandchild
        expect(event.currentTarget).toBe grandchild
        calls.push('grandchild')

      grandchild.dispatchEvent(new CustomEvent('event', bubbles: true))

      expect(calls).toEqual ['grandchild', 'child', 'parent']
