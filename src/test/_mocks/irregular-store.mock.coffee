
class MockStore
  constructor: ->
    @myCoolListeners = []
    @totalListenerCount = 0

  addMyCoolListener: (listener) ->
    @myCoolListeners.push(listener)
    @totalListenerCount += 1

  removeMyCoolListener: (listener) ->
    index = @myCoolListeners.indexOf(listener)
    if index > -1
      @myCoolListeners.splice(index, 1)

  getValue: ->
    return @id

  emitChange: ->
    @myCoolListeners.forEach (listener) =>
      listener()


module.exports = MockStore
