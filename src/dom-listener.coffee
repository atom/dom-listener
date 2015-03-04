{specificity} = require 'clear-cut'

module.exports =
class DOMListener
  constructor: (@element) ->
    @selectorBasedListenersByEventName = {}

  add: (target, eventName, handler) ->
    @element.addEventListener(eventName, @dispatchEvent) if @listenerCountForEventName(eventName) is 0
    @addSelectorBasedListener(target, eventName, handler)

  addSelectorBasedListener: (selector, eventName, handler) ->
    @selectorBasedListenersByEventName[eventName] ?= []
    @selectorBasedListenersByEventName[eventName].push(new SelectorBasedListener(selector, handler))

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

class SelectorBasedListener
  constructor: (@selector, @handler) ->
