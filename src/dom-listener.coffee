{specificity} = require 'clear-cut'
search = require 'binary-search'

SpecificityCache = {}

module.exports =
class DOMListener
  constructor: (@element) ->
    @selectorBasedListenersByEventName = {}

  add: (target, eventName, handler) ->
    if @listenerCountForEventName(eventName) is 0
      @element.addEventListener(eventName, @dispatchEvent)
    @addSelectorBasedListener(target, eventName, handler)

  addSelectorBasedListener: (selector, eventName, handler) ->
    newListener = new SelectorBasedListener(selector, handler)
    listeners = (@selectorBasedListenersByEventName[eventName] ?= [])
    index = search(listeners, newListener, (a, b) -> b.specificity - a.specificity)
    index = -index - 1 if index < 0 # index is negative index minus 1 if no exact match is found
    listeners.splice(index, 0, newListener)

  listenerCountForEventName: (eventName) ->
    @selectorBasedListenersByEventName[eventName]?.length ? 0

  dispatchEvent: (event) =>
    syntheticEvent = Object.create event,
      eventPhase: value: Event.BUBBLING_PHASE
      currentTarget: get: -> currentTarget

    currentTarget = event.target
    loop
      listeners = @selectorBasedListenersByEventName[event.type]
      if listeners and typeof currentTarget.matches is 'function'
        for listener in listeners when currentTarget.matches(listener.selector)
          listener.handler.call(currentTarget, syntheticEvent)

      break if currentTarget is @element
      currentTarget = currentTarget.parentNode

class SelectorBasedListener
  constructor: (@selector, @handler) ->
    @specificity = (SpecificityCache[@selector] ?= specificity(@selector))
