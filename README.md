# dom-listener

This library simplifies the event delegation pattern for DOM events. When you
build a `DOMListener` with a DOM node, you can associate event handles with any
of its descendant nodes via CSS selectors.

Say you have the following DOM structure.

```html
<div class="parent">
  <div class="child">
    <div class="grandchild"></div>
    <div class="grandchild"></div>
  </div>
</div>
```

Now you can associate a `click` event with all `.grandchild` nodes as follows:

```coffee
DOMListener = require 'dom-listener'

listener = new DOMListener(document.querySelector('.parent'))
listener.add '.grandchild', 'click', (event) -> # handle event...
```

## Selector-Based Handlers

To create a selector-based handler, call `DOMListener::add` with a selector,
and event name, and a callback. Handlers with selectors matching a given element
will be invoked in order of selector specificity, just like CSS. In the event
of a specificity tie, more recently added handlers will be invoked first.

```coffee
listener.add '.child.foo', 'click', (event) -> # handler 1
listener.add '.child', 'click', (event) -> # handler 2
listener.add '.child', 'click', (event) -> # handler 3
```

In the example above, all handlers match an event on `.child.foo`, but handler 1
is the most specific, so it will be invoked first. Handlers 2 and 3 are tied in
specificity, so handler 3 is invoked first since it is more recent.

## Inline Handlers

To create event handlers for specific DOM nodes, pass the node rather than a
selector as the first argument to `DOMListener::add`.

```coffee
childNode = document.querySelector('.child')
listener.add childNode, 'click', (event) -> # handle inline event...
```

This is a bit different than adding the event handler directly via the native
`.addEventListener` method, because only inline handlers registered via
`DOMListener::add` will correctly interleave with selector-based handlers.
Interleaving selector-based handlers with native event listeners isn't possible
without monkey-patching DOM APIs because you can't ask an element what event handlers are registered.

## Disposing of Handlers

If you want to remove an event handler, call `.dispose()` on the `Disposable`
returned from `DOMListener::add`:

```coffee
disposable = listener.add 'child', 'click', (event) -> # handle event
disposable.dispose() # remove event handler
```

## Destroying the Listener

If you want to remove *all* event handlers associated with the listener and
remove its native event listeners, call `DOMListener::destroy()`.

```coffee
listener.destroy() # All handlers are removed
```

You can add new event handlers and call `.destroy()` again at a later point.
