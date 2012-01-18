# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  scroll = (top) -> $(window).scrollTop(top)
  distance = (offset) -> $(window).scrollTop() + offset

  shortcut.add('I', -> document.location = '/')
  shortcut.add('A', -> scroll(0))
  shortcut.add('E', -> scroll($('body').height()))
  shortcut.add('J', (-> scroll(distance 25)), type: 'keypress')
  shortcut.add('K', (-> scroll(distance -25)), type: 'keypress')
