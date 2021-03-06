React = require 'react'

shallowDiffer = require './shallow-differ'


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

    @prevContext = @context

    for contextKey, desc of listeners
      service = @context[contextKey] or @props[contextKey]
      if service
        desc = normalizeListenerDescriptor(desc, service)
        desc.add.call(service, desc.listener)

  shouldComponentUpdate: (nextProps, nextState, nextContext) ->
    return (
      shallowDiffer(@props, nextProps) or
      shallowDiffer(@state, nextState) or
      shallowDiffer(@context, nextContext)
    )

  componentWillUpdate: (nextProps, nextState, nextContext) ->
    listeners = @getListeners(@context)
    return if !listeners

    for contextKey, desc of listeners
      service = @context[contextKey] or @props[contextKey]
      nextService = nextContext[contextKey] or nextProps[contextKey]
      if service and service != nextService
        desc = normalizeListenerDescriptor(desc, service)
        desc.remove.call(service, desc.listener)

  componentDidUpdate: (prevProps, prevState) ->
    listeners = @getListeners(@context)
    return if !listeners

    for contextKey, desc of listeners
      service = @context[contextKey] or @props[contextKey]
      prevService = @prevContext[contextKey] or prevProps[contextKey]
      if service and service != prevService
        desc = normalizeListenerDescriptor(desc, service)

        if desc.listener
          desc.listener.call(null)

        desc.add.call(service, desc.listener)
    
    @prevContext = @context

  componentWillUnmount: ->
    listeners = @getListeners(@context)
    return if !listeners

    for contextKey, desc of listeners
      service = @context[contextKey] or @props[contextKey]
      if service
        desc = normalizeListenerDescriptor(desc, service)
        desc.remove.call(service, desc.listener)


module.exports = ListenerComponent
