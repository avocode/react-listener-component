it = require 'ava'
React = require 'react'
ReactTestUtils = require 'react-addons-test-utils'
reactTestRender = require 'react-test-render'

ListenerComponent = require '../listener-component'

MockStore = require './_mocks/store.mock'
IrregularMockStore = require './_mocks/irregular-store.mock'


it 'should be renderable with no listeners set', (test) ->
  class TestComponent extends ListenerComponent
    render: ->
      React.DOM.div(null)

  renderer = reactTestRender.createRenderer(TestComponent)
  element = renderer.render()
  test.is(element.type, 'div')


it 'should register a change listener for a single store', (test) ->
  listenerCalled = false

  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: ->
      store: @_handleStoreChange

    _handleStoreChange: =>
      listenerCalled = true

    render: ->
      React.DOM.div(null)

  store = new MockStore()
  context = { store }
  renderer = reactTestRender.createRenderer(TestComponent, context)

  renderer.render()
  test.is(store.listeners.length, 1)
  store.listeners[0].call(null)
  test.true(listenerCalled)


it 'should register a change listener for a multiple stores', (test) ->
  listenerLog = []

  class TestComponent extends ListenerComponent
    @contextTypes:
      storeA: React.PropTypes.object.isRequired
      storeB: React.PropTypes.object.isRequired

    getListeners: ->
      storeA: @_handleStoreAChange
      storeB: @_handleStoreBChange

    _handleStoreAChange: =>
      listenerLog.push('A')

    _handleStoreBChange: =>
      listenerLog.push('B')

    render: ->
      React.DOM.div(null)

  storeA = new MockStore()
  storeB = new MockStore()
  context = { storeA, storeB }
  renderer = reactTestRender.createRenderer(TestComponent, context)

  renderer.render()
  test.is(storeA.listeners.length, 1)
  test.is(storeB.listeners.length, 1)
  storeA.listeners[0].call(null)
  storeB.listeners[0].call(null)
  test.is(listenerLog[0], 'A')
  test.is(listenerLog[1], 'B')


it 'should unregister the change listener of the previous store on swap',
(test) ->
  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: ->
      store: @_handleStoreChange

    _handleStoreChange: =>

    render: ->
      React.DOM.div(null)

  storeA = new MockStore()
  storeB = new MockStore()
  context = { store: storeA }
  renderer = reactTestRender.createRenderer(TestComponent, context)

  renderer.render()
  renderer.setContext({ store: storeB })
  test.is(storeA.listeners.length, 0)


it 'should register a change listener on the next store on swap',
(test) ->
  listenerCalled = false

  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: ->
      store: @_handleStoreChange

    _handleStoreChange: =>
      listenerCalled = true

    render: ->
      React.DOM.div(null)

  storeA =  new MockStore()
  context = { store: storeA }
  renderer = reactTestRender.createRenderer(TestComponent, context)
  renderer.render()

  storeB = new MockStore()
  renderer.setContext({ store: storeB })
  test.is(storeB.listeners.length, 1)
  storeB.listeners[0].call(null)
  test.true(listenerCalled)


it 'should only unregister the change listener of a swapped store', (test) ->
  class TestComponent extends ListenerComponent
    @contextTypes:
      constantStore: React.PropTypes.object.isRequired
      variableStore: React.PropTypes.object.isRequired

    getListeners: ->
      constantStore: @_handleStoreChange
      variableStore: @_handleStoreChange

    _handleStoreChange: =>

    render: ->
      React.DOM.div(null)

  storeA = new MockStore()
  storeB = new MockStore()
  context = { constantStore: storeA, variableStore: storeB }
  renderer = reactTestRender.createRenderer(TestComponent, context)
  renderer.render()

  storeC = new MockStore()
  renderer.setContext({ variableStore: storeC })
  test.is(storeB.listeners.length, 0)
  test.is(storeA.listeners.length, 1)
  test.is(storeA.totalListenerCount, 1)


it 'should unregister the change listener of the store on unmount', (test) ->
  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: ->
      store: @_handleStoreChange

    _handleStoreChange: =>

    render: ->
      React.DOM.div(null)

  store = new MockStore()
  renderer = ReactTestUtils.createRenderer()
  context = { store }
  renderer.render(React.createElement(TestComponent), context)

  AnotherComponent = ->
    React.DOM.div(null)

  # NOTE: Rendering a different element type results in an unmount.
  renderer.render(React.createElement(AnotherComponent), context)
  test.is(store.listeners.length, 0)


it 'should unregister the change listeners of multiple stores on unmount',
(test) ->
  class TestComponent extends ListenerComponent
    @contextTypes:
      storeA: React.PropTypes.object.isRequired
      storeB: React.PropTypes.object.isRequired

    getListeners: ->
      storeA: @_handleStoreChange
      storeB: @_handleStoreChange

    _handleStoreChange: =>

    render: ->
      React.DOM.div(null)

  storeA = new MockStore()
  storeB = new MockStore()
  renderer = ReactTestUtils.createRenderer()
  context = { storeA, storeB }
  renderer.render(React.createElement(TestComponent), context)

  AnotherComponent = ->
    React.DOM.div(null)

  # NOTE: Rendering a different element type results in an unmount.
  renderer.render(React.createElement(AnotherComponent), context)
  test.is(storeA.listeners.length, 0)
  test.is(storeB.listeners.length, 0)


it 'should pass the current context to the `getListener` method', (test) ->
  store = new MockStore()
  getListenersCalled = false

  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: (context) ->
      getListenersCalled = true
      test.is(typeof context, 'object')
      test.is(context.store, store)
      return {}

    render: ->
      React.DOM.div(null)

  context = { store }
  renderer = reactTestRender.createRenderer(TestComponent, context)
  renderer.render()
  test.true(getListenersCalled)


it 'should register a change listener using a custom method', (test) ->
  listenerCalled = false

  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: (context) ->
      store:
        listener: @_handleStoreChange
        add: context.store.addMyCoolListener
        remove: context.store.removeMyCoolListener

    _handleStoreChange: =>
      listenerCalled = true

    render: ->
      React.DOM.div(null)

  store = new IrregularMockStore()
  context = { store }
  renderer = reactTestRender.createRenderer(TestComponent, context)

  renderer.render()
  test.is(store.myCoolListeners.length, 1)
  store.myCoolListeners[0].call(null)
  test.true(listenerCalled)


it 'should unregister a change listener using a custom method', (test) ->
(test) ->
  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: (context) ->
      store:
        listener: @_handleStoreChange
        add: context.store.addMyCoolListener
        remove: context.store.removeMyCoolListener

    _handleStoreChange: =>

    render: ->
      React.DOM.div(null)

  store = new MockStore()
  renderer = ReactTestUtils.createRenderer()
  context = { store }
  renderer.render(React.createElement(TestComponent), context)

  AnotherComponent = ->
    React.DOM.div(null)

  # NOTE: Rendering a different element type results in an unmount.
  renderer.render(React.createElement(AnotherComponent), context)
  test.is(store.listeners.length, 0)


it 'should call the listener when stores are swap', (test) ->
  listenerCalled = false

  class TestComponent extends ListenerComponent
    @contextTypes:
      store: React.PropTypes.object.isRequired

    getListeners: ->
      store: @_handleStoreChange

    _handleStoreChange: =>
      listenerCalled = true

    render: ->
      React.DOM.div(null)

  storeA = new MockStore()
  context = { store: storeA }
  renderer = reactTestRender.createRenderer(TestComponent, context)
  renderer.render()
  test.false(listenerCalled)

  storeB = new MockStore()
  renderer.setContext({ store: storeB })
  test.true(listenerCalled)
