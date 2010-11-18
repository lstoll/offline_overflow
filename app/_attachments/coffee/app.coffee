class Post extends Backbone.Model

class PostView extends Backbone.View
  tagName: 'article'
  className: 'post'

  template: '''
            <h1>{{title}}</h1>
            {{body}}
            '''

  render: ->
    $(this.el).html Mustache.to_html(@template, @model)

class SearchResultSet extends Backbone.Collection
  model: Post

  search: (query, options) ->
    @query = query
    @url = "/search/#{query}"
    this.trigger 'query', query
    #this.trigger "refresh", []
    this.fetch()

window.SearchResults = new SearchResultSet

class SearchView extends Backbone.View
  el: $("#search")

  events:
    'submit form': 'search'

  initialize: ->
    _.bindAll this, 'search'
    SearchResults.bind 'query', =>
      this.render()
      this.$(".loading").show()
    SearchResults.bind 'refresh', =>
      this.render()
      this.$(".loading").hide()

  render: ->
    this.$("input[type=search]").val SearchResults.query
    this

  search: (event) ->
    SearchResults.search this.$("input[type=search]").getValue()
    event.preventDefault()

class SearchResultsView extends Backbone.View
  el: $("#results")

  initialize: ->
    SearchResults.bind 'refresh', => this.render()

  render: ->
    console.log 'rendering results'
    this

class PostView extends Backbone.View
  tagName: 'article'
  className: 'post'

class OfflineOverflow extends Backbone.Controller
  routes:
    'search/:query': 'search'
    'show/:post_id': 'show'
    '.*': 'home'

  search: (query) ->
    this.saveLocation "search/#{query}"
    SearchResults.search query

  show: (post_id) ->

  home: ->
    this.saveLocation ""

$(document).ready ->
  window.controller = new OfflineOverflow()
  Backbone.history.start()

  search = new SearchView().render()
  results = new SearchResultsView().render()
  $("#main").append search
  $("#main").append results

