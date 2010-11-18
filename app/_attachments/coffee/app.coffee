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

  parse: (resp) ->
    row.doc for row in resp.rows

  search: (query, options) ->
    @query = query
    @url = "../../_fti/_design/app/ranked_posts?q=#{query}&include_docs=true"
    this.trigger 'query', query
    this.fetch()

window.SearchResults = new SearchResultSet

class SearchView extends Backbone.View
  el: $("#search")

  events:
    'submit form': 'search'

  initialize: ->
    _.bindAll this, 'search'
    SearchResults.bind 'query', => this.render()
    SearchResults.bind 'refresh', => this.render()

  render: ->
    this.$("input[type=search]").val SearchResults.query
    Backbone.history.saveLocation "search/#{SearchResults.query}"
    this

  search: (event) ->
    SearchResults.search this.$("input[type=search]").val()
    event.preventDefault()
    false

class SearchResultsView extends Backbone.View
  el: $("#results")

  initialize: ->
    SearchResults.bind 'query', => this.$(".loading").show()
    SearchResults.bind 'refresh', => this.render()

  render: ->
    this.$(".post").remove()
    this.$(".loading").hide()
    SearchResults.each (post) => this.addResult post
    this

  addResult: (post) ->
    view = new PostView(model: post)
    $(this.el).append(view.render().el)

class PostView extends Backbone.View
  tagName: 'article'
  className: 'post'

  template: '''
            <h1>{{Title}}</h1>
            {{{Body}}}
            '''

  render: ->
    $(this.el).html Mustache.to_html(@template, @model.toJSON())
    this

class OfflineOverflow extends Backbone.Controller
  routes:
    'search/:query': 'search'
    'show/:post_id': 'show'

  search: (query) ->
    this.saveLocation "search/#{query}"
    SearchResults.search query

  show: (post_id) ->

$(document).ready ->
  window.controller = new OfflineOverflow()
  Backbone.history.start()

  search = new SearchView().render()
  results = new SearchResultsView().render()
  $("#main").append search
  $("#main").append results

