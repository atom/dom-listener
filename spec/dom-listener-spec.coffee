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
        expect(event.eventPhase).toBe Event.BUBBLING_PHASE
        calls.push('parent')

      listener.add '.child', 'event', (event) ->
        expect(this).toBe child
        expect(event.target).toBe grandchild
        expect(event.currentTarget).toBe child
        expect(event.eventPhase).toBe Event.BUBBLING_PHASE
        calls.push('child')

      listener.add '.grandchild', 'event', (event) ->
        expect(this).toBe grandchild
        expect(event.target).toBe grandchild
        expect(event.currentTarget).toBe grandchild
        expect(event.eventPhase).toBe Event.BUBBLING_PHASE
        calls.push('grandchild')

      grandchild.dispatchEvent(new CustomEvent('event', bubbles: true))

      expect(calls).toEqual ['grandchild', 'child', 'parent']

    it "invokes multiple matching callbacks for the same element by selector specificity, then recency", ->
      child.classList.add('foo', 'bar')
      calls = []

      listener.add '.child.foo.bar', 'event', -> calls.push('b')
      listener.add '.child.foo.bar', 'event', -> calls.push('a')
      listener.add '.child.foo', 'event', -> calls.push('c')
      listener.add '.child', 'event', -> calls.push('d')

      grandchild.dispatchEvent(new CustomEvent('event', bubbles: true))

      expect(calls).toEqual ['a', 'b', 'c', 'd']
