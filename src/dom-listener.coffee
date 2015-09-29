{Disposable} = require 'event-kit'
{specificity} = require 'clear-cut'
search = require 'binary-search'

SpecificityCache = {}

module.exports =
class DOMListener
  constructor: (@element) ->
    @selectorBasedListenersByEventName = {}
    @inlineListenersByEventName = {}
    @nativeEventListeners = {}

  add: (target, eventName, handler) ->
    unless @nativeEventListeners[eventName]
      @element.addEventListener(eventName, @dispatchEvent)
      @nativeEventListeners[eventName] = true

    if typeof target is 'string'
      @addSelectorBasedListener(target, eventName, handler)
    else
      @addInlineListener(target, eventName, handler)

  destroy: ->
    for eventName of @nativeEventListeners
      @element.removeEventListener(eventName, @dispatchEvent)
    @selectorBasedListenersByEventName = {}
    @inlineListenersByEventName = {}
    @nativeEventListeners = {}

  addSelectorBasedListener: (selector, eventName, handler) ->
    newListener = new SelectorBasedListener(selector, handler)
    listeners = (@selectorBasedListenersByEventName[eventName] ?= [])
    index = search(listeners, newListener, (a, b) -> b.specificity - a.specificity)
    index = -index - 1 if index < 0 # index is negative index minus 1 if no exact match is found
    listeners.splice(index, 0, newListener)

    new Disposable ->
      index = listeners.indexOf(newListener)
      listeners.splice(index, 1)

  addInlineListener: (node, eventName, handler) ->
    listenersByNode = (@inlineListenersByEventName[eventName] ?= new WeakMap)
    unless listeners = listenersByNode.get(node)
      listeners = []
      listenersByNode.set(node, listeners)
    listeners.push(handler)

    new Disposable ->
      index = listeners.indexOf(handler)
      listeners.splice(index, 1)

  dispatchEvent: (event) =>
    currentTarget = event.target
    propagationStopped = false
    immediatePropagationStopped = false
    defaultPrevented = false

    descriptor = {
      type: value: event.type
      detail: value: event.detail
      eventPhase: value: Event.BUBBLING_PHASE
      target: value: currentTarget
      currentTarget: get: -> currentTarget
      stopPropagation: value: ->
        propagationStopped = true
        event.stopPropagation()
      stopImmediatePropagation: value: ->
        propagationStopped = true
        immediatePropagationStopped = true
        event.stopImmediatePropagation()
      preventDefault: value: ->
        defaultPrevented = true
        event.preventDefault()
      defaultPrevented: get: -> defaultPrevented
    }

    for key, value of event
      descriptor[key] ?= {value}

    syntheticEvent = Object.create(event.constructor.prototype, descriptor)

    loop
      inlineListeners = @inlineListenersByEventName[event.type]?.get(currentTarget)
      if inlineListeners?
        for handler in inlineListeners
          handler.call(currentTarget, syntheticEvent)
          break if immediatePropagationStopped

      break if immediatePropagationStopped

      selectorBasedListeners = @selectorBasedListenersByEventName[event.type]
      if selectorBasedListeners? and typeof currentTarget.matches is 'function'
        for listener in selectorBasedListeners when currentTarget.matches(listener.selector)
          listener.handler.call(currentTarget, syntheticEvent)
          break if immediatePropagationStopped

      break if propagationStopped
      break if currentTarget is @element
      currentTarget = currentTarget.parentNode

class SelectorBasedListener
  constructor: (@selector, @handler) ->
    @specificity = (SpecificityCache[@selector] ?= specificity(@selector))
