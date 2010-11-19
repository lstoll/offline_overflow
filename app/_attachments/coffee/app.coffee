class Post extends Backbone.Model
  url: ->
    "../../#{this.get '_id'}"

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
    _(row.doc).extend(id: row.id) for row in resp.rows

  comparator: (post) ->
    -1 * parseInt(post.get('Score'))

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

  template: '''
            {{#posts}}
              <article id="{{_id}}">
                <a href="#show/{{_id}}">
                  <h1>{{Title}}</h1>
                  <h2>Score {{Score}}</h2>
                </a>
              </article>
            {{/posts}}
            '''

  loadingTemplate: '<img src="ajax-loader.gif" class="loading">'

  initialize: ->
    SearchResults.bind 'query', => this.$(".loading").show()
    SearchResults.bind 'refresh', => this.render()

  render: (loading) ->
    if loading
      $(this.el).html @loadingTemplate
    else
      $(this.el).html Mustache.to_html(@template, { posts: SearchResults.toJSON() })

    this

class PostView extends Backbone.View
  tagName: 'article'

  template: '''
            <header>
              <h1>{{Title}}</h1>
            </header>
            <section class="question">
              {{{Body}}}
              <ul class="comments">
                {{#comments}}<li>{{Text}}</li>{{/comments}}
              </ul>
            </section>
            <ul class="answers">
              {{#answers}}
                <li>
                  {{{Body}}}
                  <ul class="comments">
                    {{#comments}}<li>{{Text}}</li>{{/comments}}
                  </ul>
                </li>
              {{/answers}}
            </ul>
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
    this.saveLocation "show/#{post_id}"
    model = SearchResults.get(post_id)
    unless model?
      model = new Post({_id: post_id})
      model.fetch()
    view = new PostView(model: model)
    $("#main > article").remove()
    $("#main").prepend view.render().el

$(document).ready ->
  window.controller = new OfflineOverflow()
  Backbone.history.start()

  search = new SearchView().render()
  results = new SearchResultsView().render()
  $("#main").append search
  $("#main").append results

