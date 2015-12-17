React = require 'react'


normalizeListenerDescriptor = (desc, service) ->
  if typeof desc == 'function'
    desc =
      listener: desc

  if !desc.add
    desc.add = service.addChangeListener or service.addListener
  if !desc.remove
    desc.remove = service.removeChangeListener or service.removeListener

  return desc


class ListenerComponent extends React.Component
  getListeners: ->
    return null

  componentDidMount: ->
    listeners = @getListeners(@context)
    return if !listeners

    for contextKey, desc of listeners
      service = @context[contextKey]
      if service
        desc = normalizeListenerDescriptor(desc, service)
        desc.add.call(service, desc.listener)

  componentWillUpdate: (nextProps, nextState, nextContext) ->
    listeners = @getListeners(@context)
    return if !listeners

    for contextKey, desc of listeners
      service = @context[contextKey]
      if service and service != nextContext[contextKey]
        desc = normalizeListenerDescriptor(desc, service)
        desc.remove.call(service, desc.listener)

  componentDidUpdate: (prevProps, prevState, prevContext) ->
    listeners = @getListeners(@context)
    return if !listeners

    for contextKey, desc of listeners
      service = @context[contextKey]
      if service and service != prevContext[contextKey]
        desc = normalizeListenerDescriptor(desc, service)
        desc.listener.call(null)
        desc.add.call(service, desc.listener)

  componentWillUnmount: ->
    listeners = @getListeners(@context)
    return if !listeners

    for contextKey, desc of listeners
      service = @context[contextKey]
      if service
        desc = normalizeListenerDescriptor(desc, service)
        desc.remove.call(service, desc.listener)


module.exports = ListenerComponent
