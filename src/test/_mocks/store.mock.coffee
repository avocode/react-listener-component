
class MockStore
  constructor: ->
    @listeners = []
    @totalListenerCount = 0

  addChangeListener: (listener) ->
    @listeners.push(listener)
    @totalListenerCount += 1

  removeChangeListener: (listener) ->
    index = @listeners.indexOf(listener)
    if index > -1
      @listeners.splice(index, 1)

  getValue: ->
    return @id

  emitChange: ->
    @listeners.forEach (listener) =>
      listener()


module.exports = MockStore
