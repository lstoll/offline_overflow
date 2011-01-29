class Post extends Backbone.Model
  url: ->
    "../../#{this.id}"

class SearchResult extends Backbone.Model
  initialize: ->
    this.post = new Post(id: this.postId())

  hasParentId: ->
    false

  postId: ->
    if this.hasParentId()
      this.get('doc').parentId
    else
      this.id

class SearchResults extends Backbone.Collection
  model: SearchResult

  parse: (data) ->
    data.rows

  search: (query) ->
    this.url = "../../_fti/_design/app/ranked_posts?q=#{query}&include_docs=true"
    this.fetch()

  comparator: (result) ->
    -1 * parseInt(result.get('score'))

class HomeView extends Backbone.View
  template: '''
            <form>
              <input type="search">
              <button type="submit">Search</button>
            </form>
            '''

  events:
    'submit form': 'search'

  render: ->
    $(this.el).html(Mustache.to_html(this.template))
    this

  searchQuery: ->
    this.$("input[type=search]").val()

  search: ->
    Backbone.history.saveLocation "search/#{this.searchQuery()}"
    false

class SearchResultsView extends Backbone.View
  className: 'results'

  initialize: ->
    this.collection.bind "refresh", => this.render()

  render: ->
    this.collection.each (result) =>
      $(this.el).append(new SearchResultView(model: result).render().el)
    this

class SearchResultView extends Backbone.View
  tagName: 'article'

  template: '''
            <h1>{{Title}}</h1>
            <p class="exerpt">{{{Body}}}</p>
            '''

  events:
    'click h1': 'select'

  initialize: ->
    this.model.bind 'postLoaded', 'render'

  render: ->
    $(this.el).html(Mustache.to_html(this.template, this.model.get('doc')))
    this

  select: ->
    Backbone.history.saveLocation("posts/#{this.model.postId()}")

window.SearchResults = new SearchResults()

class PostView extends Backbone.View
  tagName: 'article'

  template: '''
            <h1>{{Title}}</h1>
            {{{Body}}}
            '''

  initialize: ->
    this.model.bind 'change', => this.render()

  render: ->
    $(this.el).html(Mustache.to_html(this.template, this.model.toJSON()))
    this

class StackUnderflow extends Backbone.Controller
  views: {}

  routes:
    '': 'home'
    'home': 'home'
    'search/:query': 'search'
    'posts/:post_id': 'show'

  initialize: ->
    this.views.home = new HomeView().render()
    this.views.results = new SearchResultsView(collection: window.SearchResults).render()

  home: ->
    $("#main").html(this.views.home.el)

  search: (query) ->
    window.SearchResults.search query
    $("#main").html(this.views.results.el)

  show: (post_id) ->
    console.log post_id
    post = new Post(id: post_id)
    $("#main").html(new PostView(model: post).render().el)
    post.fetch()

$(document).ready ->
  window.controller = new StackUnderflow()
  Backbone.history.start()